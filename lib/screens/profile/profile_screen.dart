import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/profile_storage.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? profileImage;
  String? profileImageUri;

  Future<void> _loadProfile() async {
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) {
        setState(() => profile = {'name': 'Guest user', 'role': 'Guest'});
      }
      return;
    }
    try {
      final value = await ProfileStorage.load();
      if (mounted) {
        setState(() {
          profile = value;
          profileImageUri = value['image'];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load your profile. Please try again.'),
          ),
        );
      }
    }
  }

  Map<String, dynamic> profile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.center,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar with camera edit badge matching Profile in Figma
              Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImage != null
                          ? Image.memory(profileImage!, fit: BoxFit.cover)
                          : profileImageUri != null
                          ? Image.network(profileImageUri!, fit: BoxFit.cover)
                          : Image.asset(
                              'assets/images/profile_photo.jfif',
                              fit: BoxFit.cover,
                              width: 90,
                              height: 90,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/edit_profile',
                          );
                          if (result is Uint8List && mounted) {
                            setState(() => profileImage = result);
                          }
                          _loadProfile();
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                profile['name'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                profile['role'] ?? 'Student',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),

              // About Me
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      'About Me',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      profile['about'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info List Cards matching Profile in Figma
              _buildInfoRow(
                Icons.school_outlined,
                'Faculty',
                profile['faculty'] ?? '',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.cake_outlined,
                'Birthday',
                profile['birthday'] ?? '',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.badge_outlined,
                'Year',
                profile['year'] ?? '',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.location_on_outlined,
                'District',
                profile['district'] ?? '',
              ),
              const SizedBox(height: 36),

              if (profile['role'] == 'Recruiter') ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/recruiter'),
                  icon: const Icon(Icons.work_outline),
                  label: const Text('Recruiter Portal'),
                ),
                const SizedBox(height: 16),
              ],

              // Log Out button matching Figma Profile screen
              ElevatedButton(
                onPressed: () async {
                  try {
                    await AuthService.signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (_) => false,
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to sign out. Please try again.'),
                      ),
                    );
                  }
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
