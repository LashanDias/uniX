/// Room inventory for the girls hostel (HUB 02).
///
/// Structure supplied by the university: 23 rooms on each floor, of which 3 are
/// 6-sharing and the rest 4-sharing, for 60+ rooms in the building.
///
/// Availability is derived from the room number rather than a random number
/// generator, so a room shows the same free-bed count every time the screen is
/// rebuilt. Without that, scrolling the list would reshuffle availability.
class GirlsHostelInventory {
  /// Floors that take students, in the order they are shown.
  static const floors = ['Ground Floor', '1st Floor', '2nd Floor'];

  static const roomsPerFloor = 23;

  /// The first [sixSharingPerFloor] rooms on each floor are 6-sharing.
  static const sixSharingPerFloor = 3;

  static int get totalRooms => floors.length * roomsPerFloor;

  static int get fourSharingPerFloor => roomsPerFloor - sixSharingPerFloor;

  /// Monthly rate in LKR for a whole room.
  static int monthlyPrice(int sharing) => sharing == 6 ? 8000 : 9500;

  /// Daily rate in LKR for a whole room.
  static int dailyPrice(int sharing) => sharing == 6 ? 600 : 900;

  /// Weekly rate in LKR for a whole room.
  static int weeklyPrice(int sharing) => sharing == 6 ? 2250 : 2500;

  /// How many students share [roomOnFloor] (1-based) on any floor.
  static int sharingFor(int roomOnFloor) =>
      roomOnFloor <= sixSharingPerFloor ? 6 : 4;

  /// Room label, e.g. floor 2 room 7 is `0207`.
  static String numberFor(int floorIndex, int roomOnFloor) =>
      '${floorIndex.toString().padLeft(2, '0')}'
      '${roomOnFloor.toString().padLeft(2, '0')}';

  /// Free beds in [number], stable for a given room number.
  static int bedsAvailableFor(String number, int sharing) {
    var hash = 7;
    for (final unit in number.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % (sharing + 1);
  }

  /// Every room on [floorIndex], in room-number order.
  static List<HostelRoom> roomsOn(int floorIndex) => [
    for (var room = 1; room <= roomsPerFloor; room++)
      HostelRoom._forPosition(floorIndex, room),
  ];

  /// Rooms on [floorIndex] that still have at least one free bed.
  static List<HostelRoom> availableOn(int floorIndex) =>
      roomsOn(floorIndex).where((room) => !room.isFull).toList();
}

/// A single bookable room.
class HostelRoom {
  const HostelRoom({
    required this.number,
    required this.floorIndex,
    required this.sharing,
    required this.bedsAvailable,
  });

  factory HostelRoom._forPosition(int floorIndex, int roomOnFloor) {
    final sharing = GirlsHostelInventory.sharingFor(roomOnFloor);
    final number = GirlsHostelInventory.numberFor(floorIndex, roomOnFloor);
    return HostelRoom(
      number: number,
      floorIndex: floorIndex,
      sharing: sharing,
      bedsAvailable: GirlsHostelInventory.bedsAvailableFor(number, sharing),
    );
  }

  final String number;
  final int floorIndex;
  final int sharing;
  final int bedsAvailable;

  bool get isFull => bedsAvailable == 0;

  String get typeLabel => '$sharing-sharing';

  String get floorLabel => GirlsHostelInventory.floors[floorIndex];

  int get monthlyPrice => GirlsHostelInventory.monthlyPrice(sharing);

  String get bedsLabel => isFull
      ? 'Fully booked'
      : '$bedsAvailable ${bedsAvailable == 1 ? 'bed' : 'beds'} available';
}
