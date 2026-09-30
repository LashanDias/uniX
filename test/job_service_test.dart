import 'package:flutter_test/flutter_test.dart';
import 'package:unix_app/models/app_models.dart';
import 'package:unix_app/services/job_service.dart';

void main() {
  test('Job service builds a JobItem from a Firestore document', () {
    final job = JobService.fromDocument({
      'title': 'Intern Data Analyst',
      'company': 'SLTC Digital',
      'location': 'Colombo 03 • Hybrid',
      'type': 'Internship',
      'matchPercentage': 92,
      'logoUrl': 'https://example.com/logo.png',
      'recruiterId': 'hr-1',
      'requirements': 'Dart and Flutter',
      'description': 'Build apps',
      'contactEmail': 'hr@company.com',
    }, id: 'job-1');

    expect(job.id, 'job-1');
    expect(job.title, 'Intern Data Analyst');
    expect(job.company, 'SLTC Digital');
    expect(job.location, 'Colombo 03 • Hybrid');
    expect(job.type, 'Internship');
    expect(job.matchPercentage, 92);
    expect(job.logoUrl, 'https://example.com/logo.png');
    expect(job.recruiterId, 'hr-1');
    expect(job.requirements, 'Dart and Flutter');
    expect(job.description, 'Build apps');
    expect(job.contactEmail, 'hr@company.com');
  });

  test('Job service creates a saveable Firestore payload', () {
    final payload = JobService.toDocument(
      JobItem(
        id: 'job-2',
        title: 'UI Design Intern',
        company: 'Pixel Labs',
        location: 'Kandy • Hybrid',
        type: 'Internship',
        matchPercentage: 89,
        logoUrl: '',
        recruiterId: 'hr-2',
        requirements: 'Figma and prototyping',
        description: 'Design interfaces',
        contactEmail: 'hr@pixel.com',
      ),
    );

    expect(payload['title'], 'UI Design Intern');
    expect(payload['company'], 'Pixel Labs');
    expect(payload['location'], 'Kandy • Hybrid');
    expect(payload['type'], 'Internship');
    expect(payload['matchPercentage'], 89);
    expect(payload.containsKey('postedAt'), isTrue);
    expect(payload['recruiterId'], 'hr-2');
    expect(payload['requirements'], 'Figma and prototyping');
    expect(payload['description'], 'Design interfaces');
    expect(payload['contactEmail'], 'hr@pixel.com');
  });
}
