import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../services/mock_data_service.dart';

class CareerPassportScreen extends StatelessWidget {
  const CareerPassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CareerPassportModel passport = MockDataService.getSamplePassport();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UNIX Career Passport 🏆'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              // Passport Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002DDF), Color(0xFF1E3A8A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            color: Colors.white24,
                          ),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(
                              passport.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              passport.title,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Passport ID: UNIX-98421', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('VERIFIED STUDENT ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Verified Skills Section (Competition Highlight 🔥)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified, color: AppColors.success, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Verified Skills (Company Approved)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: passport.verifiedSkills.map((skill) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.badgeGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.badgeGreenText),
                            const SizedBox(width: 4),
                            Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.badgeGreenText)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Education
              _buildSectionCard(
                icon: Icons.school,
                title: 'Education',
                content: passport.education,
              ),
              const SizedBox(height: 16),

              // Skills
              _buildSectionCard(
                icon: Icons.psychology,
                title: 'Skills',
                contentWidget: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: passport.skills.map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.chipBg,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Projects
              _buildSectionCard(
                icon: Icons.folder,
                title: 'Projects',
                contentWidget: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: passport.projects.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, color: AppColors.primary),
                        Text(p, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Certificates
              _buildSectionCard(
                icon: Icons.workspace_premium,
                title: 'Certificates',
                contentWidget: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: passport.certificates.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          if (content != null) Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ?contentWidget,
        ],
      ),
    );
  }
}
