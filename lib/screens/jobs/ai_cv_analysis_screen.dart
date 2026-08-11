import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AiCvAnalysisScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const AiCvAnalysisScreen({
    super.key,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: onPrev,
              ),
              const Expanded(
                child: Text(
                  'AI CV Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'We have successfully analyzed your CV and extracted the important Information.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // AI Mascot Banner matching Figma iPhone 16 & 17 Pro Max - 12
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF002DDF), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: const [
                      Text(
                        'AI is analyzing your CV...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'extracting your skills, education, experience, projects and certifications.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 48),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Extracted Info Sections
          _buildExtractedCard(
            icon: Icons.school_outlined,
            title: 'Education',
            subtitle: 'BSc in Data Science',
            detail: 'University of SLTC, Sri Lanka • 2021-2025',
          ),
          const SizedBox(height: 12),
          _buildExtractedCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Certifications',
            subtitle: 'Google Data Analytics professional certificate',
            detail: 'Microsoft Power BI Data Analyst Associate',
            hasViewAll: true,
          ),
          const SizedBox(height: 12),
          _buildExtractedCard(
            icon: Icons.folder_special_outlined,
            title: 'Project',
            subtitle: 'Sales Dashboard using Power BI',
            detail: 'Customer Segmentation with Python\nData Cleaning and Analysis using SQL',
            hasViewAll: true,
          ),
          const SizedBox(height: 12),
          _buildExtractedCard(
            icon: Icons.work_history_outlined,
            title: 'Experience',
            subtitle: 'Data Analyst Intern',
            detail: 'Dialog Axiata PLC • Jan 2024 - Present',
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('Continue to Skill Match'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
    bool hasViewAll = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (hasViewAll)
                      const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
        ],
      ),
    );
  }
}
