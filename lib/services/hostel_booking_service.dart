import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'girls_hostel_inventory.dart';

/// A room request a student has submitted.
class HostelBooking {
  const HostelBooking({
    required this.id,
    required this.hostel,
    required this.roomNumber,
    required this.floor,
    required this.sharing,
    required this.monthlyPrice,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.reference,
    required this.requestedAt,
  });

  final String id;
  final String hostel;
  final String roomNumber;
  final String floor;
  final int sharing;
  final int monthlyPrice;
  final DateTime checkIn;
  final DateTime checkOut;

  /// Where the request has got to.
  final String status;

  /// Short code the student quotes to the warden.
  final String reference;

  final DateTime requestedAt;

  /// Statuses a booking moves through. Only an admin advances it.
  static const statuses = [
    'Requested',
    'Confirmed',
    'Paid',
    'Cancelled',
  ];

  int get nights => DateTime.utc(checkOut.year, checkOut.month, checkOut.day)
      .difference(DateTime.utc(checkIn.year, checkIn.month, checkIn.day))
      .inDays;

  static HostelBooking fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return HostelBooking(
      id: doc.id,
      hostel: (data['hostel'] ?? '').toString(),
      roomNumber: (data['roomNumber'] ?? '').toString(),
      floor: (data['floor'] ?? '').toString(),
      sharing: (data['sharing'] as num?)?.toInt() ?? 0,
      monthlyPrice: (data['monthlyPrice'] as num?)?.toInt() ?? 0,
      checkIn: (data['checkIn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checkOut: (data['checkOut'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (data['status'] ?? 'Requested').toString(),
      reference: (data['reference'] ?? '').toString(),
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Submits and reads hostel room requests.
///
/// A booking used to be a note in the device's own storage that said "no room
/// has been reserved", which is not a booking at all. A request now goes to
/// Firestore where the warden can see it, and comes back with a reference.
///
/// It is a request, not a confirmed room: only an admin moves it past
/// Requested, and no payment is taken here.
class HostelBookingService {
  static const collection = 'hostelBookings';

  /// Longest stay a student can request.
  static const maxNights = 90;

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Short reference the student quotes to the warden.
  static String buildReference(DateTime at) {
    final stamp = at.millisecondsSinceEpoch.remainder(100000);
    return 'HB${stamp.toString().padLeft(5, '0')}';
  }

  /// Nights between two dates, counted on calendar days.
  static int nightsBetween(DateTime checkIn, DateTime checkOut) =>
      DateTime.utc(checkOut.year, checkOut.month, checkOut.day)
          .difference(DateTime.utc(checkIn.year, checkIn.month, checkIn.day))
          .inDays;

  /// Checks a stay is one the hostel accepts.
  ///
  /// Returns null when it is fine, or the reason it is not.
  static String? validateStay(DateTime checkIn, DateTime checkOut) {
    final nights = nightsBetween(checkIn, checkOut);
    if (nights < 1) return 'Choose a check-out date after your check-in date.';
    if (nights > maxNights) {
      return 'The longest stay is $maxNights nights. Choose a shorter range.';
    }
    return null;
  }

  /// Submits a request for [room].
  static Future<HostelBooking> book({
    required HostelRoom room,
    required DateTime checkIn,
    required DateTime checkOut,
    String hostel = 'Girls Hostel • HUB 02',
  }) async {
    // Check the request itself before reaching for Firebase, so a bad room or
    // an impossible stay is rejected the same way whether or not the network
    // or the Firebase app is available.
    if (room.isFull) {
      throw StateError('Room ${room.number} has no free beds.');
    }
    final problem = validateStay(checkIn, checkOut);
    if (problem != null) throw StateError(problem);

    final user = _currentUser();
    if (user == null) {
      throw StateError('Please sign in to request a room.');
    }

    final at = DateTime.now();
    final reference = buildReference(at);

    final doc = await _db.collection(collection).add({
      'userId': user.uid,
      'hostel': hostel,
      'roomNumber': room.number,
      'floor': room.floorLabel,
      'sharing': room.sharing,
      'monthlyPrice': room.monthlyPrice,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'status': 'Requested',
      'reference': reference,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    return HostelBooking(
      id: doc.id,
      hostel: hostel,
      roomNumber: room.number,
      floor: room.floorLabel,
      sharing: room.sharing,
      monthlyPrice: room.monthlyPrice,
      checkIn: checkIn,
      checkOut: checkOut,
      status: 'Requested',
      reference: reference,
      requestedAt: at,
    );
  }

  /// The signed-in user, or null when nobody is signed in or Firebase is
  /// unavailable.
  static User? _currentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// The signed-in student's own requests, newest first.
  static Stream<List<HostelBooking>> watchMyBookings() {
    final user = _currentUser();
    if (user == null) return Stream.value(const []);
    return _db
        .collection(collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HostelBooking.fromDoc).toList());
  }
}
