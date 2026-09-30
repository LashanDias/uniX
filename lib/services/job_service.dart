import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';

class JobService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String jobsCollection = 'jobs';

  static JobItem fromDocument(Map<String, dynamic> data, {required String id}) {
    return JobItem(
      id: id,
      title: (data['title'] ?? 'Untitled job').toString(),
      company: (data['company'] ?? 'Unknown company').toString(),
      location: (data['location'] ?? 'Remote').toString(),
      type: (data['type'] ?? 'Internship').toString(),
      matchPercentage: (data['matchPercentage'] is int)
          ? data['matchPercentage'] as int
          : int.tryParse((data['matchPercentage'] ?? '0').toString()) ?? 0,
      logoUrl: (data['logoUrl'] ?? '').toString(),
      recruiterId: (data['recruiterId'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      requirements: (data['requirements'] ?? '').toString(),
      contactEmail: (data['contactEmail'] ?? '').toString(),
    );
  }

  static Map<String, dynamic> toDocument(JobItem job) {
    return {
      'title': job.title,
      'company': job.company,
      'location': job.location,
      'type': job.type,
      'matchPercentage': job.matchPercentage,
      'logoUrl': job.logoUrl,
      'recruiterId': job.recruiterId,
      'description': job.description,
      'requirements': job.requirements,
      'contactEmail': job.contactEmail,
      'postedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Stream<List<JobItem>> watchJobs() {
    return _db
        .collection(jobsCollection)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => fromDocument(doc.data(), id: doc.id))
              .toList(),
        );
  }

  static Future<void> saveJob(JobItem job) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || job.recruiterId != user.uid) {
      throw StateError('Sign in with your recruiter account to publish a job.');
    }
    final id = job.id.isNotEmpty
        ? job.id
        : _db.collection(jobsCollection).doc().id;
    final docRef = _db.collection(jobsCollection).doc(id);
    await docRef.set(toDocument(job), SetOptions(merge: true));
  }

  static Stream<List<JobItem>> watchRecruiterJobs(String recruiterId) => _db
      .collection(jobsCollection)
      .where('recruiterId', isEqualTo: recruiterId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => fromDocument(doc.data(), id: doc.id))
            .toList(),
      );

  static Future<void> saveJobs(List<JobItem> jobs) async {
    final batch = _db.batch();
    for (final job in jobs) {
      final id = job.id.isNotEmpty
          ? job.id
          : _db.collection(jobsCollection).doc().id;
      final ref = _db.collection(jobsCollection).doc(id);
      batch.set(ref, toDocument(job), SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<void> ensureDemoJobs() async {
    final snapshot = await _db.collection(jobsCollection).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    await saveJobs([
      JobItem(
        id: 'demo-1',
        title: 'Data Analyst Intern',
        company: 'Dialog Axiata PLC',
        location: 'Colombo 02 • Hybrid',
        type: 'Internship',
        matchPercentage: 94,
        logoUrl: '',
      ),
      JobItem(
        id: 'demo-2',
        title: 'Junior Data Analyst',
        company: 'Creative Software',
        location: 'Colombo 03 • Full-time',
        type: 'Full-time',
        matchPercentage: 91,
        logoUrl: '',
      ),
      JobItem(
        id: 'demo-3',
        title: 'Business Intelligence Intern',
        company: 'WSO2',
        location: 'Colombo 04 • Hybrid',
        type: 'Internship',
        matchPercentage: 88,
        logoUrl: '',
      ),
    ]);
  }
}
