import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildNotificationItem(
              icon: Icons.work_outline,
              title: '🔔 New Job Match',
              subtitle: 'A Data Analyst Internship matches 91% of your profile.',
              time: '10 min ago',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.flash_on,
              title: '🎉 Gig Approved',
              subtitle: 'Your Data Cleaning Gig has been approved.',
              time: '1 hour ago',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.verified_user_outlined,
              title: '✅ Verified Skill',
              subtitle: 'Pandas has been added to your verified skills.',
              time: '2 hours ago',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Text(time, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
