import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/job_service.dart';
import '../jobs/recruitment_workspace_screen.dart';
import 'post_job_screen.dart';

class RecruiterDashboardScreen extends StatelessWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return RecruitmentWorkspaceScreen(
      accountId: user?.uid ?? 'guest',
      recruiterMode: true,
      profileName: user?.displayName ?? '',
      profileEmail: user?.email ?? '',
      onPublishVacancy: user == null
          ? null
          : () async {
              final published = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PostJobScreen(
                    recruiterId: user.uid,
                    contactEmail: user.email ?? '',
                    onPublish: JobService.saveJob,
                  ),
                ),
              );
              if (published == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vacancy published.')),
                );
              }
            },
    );
  }
}
