import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SkillMatchScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const SkillMatchScreen({
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
                  'Skill Match Analysis',
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
            'We compare your skills with the job requirements to calculate your match score.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Overall Match score card with circular 94% badge matching Figma iPhone 16 & 17 Pro Max - 46
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('Top 10% of applicants', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: const [
                    Text('Overall Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Excellent match', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('you are a strong match for this opportunity', style: TextStyle(color: AppColors.textLight, fontSize: 9)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: const Center(
                    child: Text('94%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Match Breakdown horizontal progress indicators
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text('Match Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 14),
                _buildProgressBar('Skill Match', 0.78, Colors.purple, '78%'),
                const SizedBox(height: 10),
                _buildProgressBar('Education Match', 1.0, AppColors.primary, '100%'),
                const SizedBox(height: 10),
                _buildProgressBar('Experience Match', 0.84, Colors.amber.shade700, '84%'),
                const SizedBox(height: 10),
                _buildProgressBar('Location Match', 1.0, AppColors.success, '100%'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Matched Skills list box matching Figma
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text('Matched Skills', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: const [
                    Text('Python', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    Text('SQL', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    Text('Power BI', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    Text('Data Analysis', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    Text('Communication', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    Text('Problem Solving', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Skills to Improve
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                const Text('Skills to Improve', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: const [
                    Text('Advanced SQL', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Statistics', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Azure', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Data Visualization', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 4),
                    Text('Cloud computing', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // AI Career Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Career Tip\nLearning Advanced SQL and Statistics can significantly increase match Score and Open more opportunities.',
                    style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: onNext,
            child: const Text('View Recommended Jobs'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double val, Color color, String percentText) {
    return Column(
      crossAxisAlignment: CrossAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(percentText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: val,
            color: color,
            backgroundColor: AppColors.chipBg,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
