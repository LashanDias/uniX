import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'career_flow_screen.dart';

class JobsHomeScreen extends StatelessWidget {
  const JobsHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return CareerFlowScreen(
      accountId: user?.uid ?? 'guest',
      profileName: user?.displayName ?? '',
      profileEmail: user?.email ?? '',
    );
  }
}
