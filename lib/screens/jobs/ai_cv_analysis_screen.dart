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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: onPrev,
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'AI CV Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'We have successfully analyzed your CV and extracted the important information.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 122,
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF002DDF), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI is analyzing your CV...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'extracting your skills, education, experience, projects and certifications.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 105,
                      height: 110,
                      child: Image.asset(
                        'assets/images/ai_robot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildExtractedCard(
                icon: Icons.school_outlined,
                title: 'Education',
                subtitle: 'BSc in Data Science',
                detail: 'University of SLTC, Sri Lanka • 2021-2025',
              ),
              const SizedBox(height: 9),
              _buildExtractedCard(
                icon: Icons.workspace_premium_outlined,
                title: 'Certifications',
                subtitle: 'Google Data Analytics professional certificate',
                detail: 'Microsoft Power BI Data Analyst Associate',
                hasViewAll: true,
              ),
              const SizedBox(height: 9),
              _buildExtractedCard(
                icon: Icons.folder_special_outlined,
                title: 'Project',
                subtitle: 'Sales Dashboard using Power BI',
                detail:
                    'Customer Segmentation with Python\nData Cleaning and Analysis using SQL',
                hasViewAll: true,
              ),
              const SizedBox(height: 9),
              _buildExtractedCard(
                icon: Icons.work_history_outlined,
                title: 'Experience',
                subtitle: 'Data Analyst Intern',
                detail: 'Dialog Axiata PLC • Jan 2024 - Present',
              ),
              const SizedBox(height: 44),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text('Continue to Skill'),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (hasViewAll)
                      const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 9,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (!hasViewAll) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
              size: 17,
            ),
          ],
        ],
      ),
    );
  }
}
