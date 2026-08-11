import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UploadCvScreen extends StatefulWidget {
  final VoidCallback onNext;

  const UploadCvScreen({super.key, required this.onNext});

  @override
  State<UploadCvScreen> createState() => _UploadCvScreenState();
}

class _UploadCvScreenState extends State<UploadCvScreen> {
  String selectedFile = "";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          const Text(
            'Upload your CV',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload your CV to discover jobs and internships that match your skills, education and experience.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Drag & Drop CV upload box matching Figma iPhone 16 & 17 Pro Max - 41
          GestureDetector(
            onTap: () {
              setState(() {
                selectedFile = "Amaangi_Resume_DataScience.pdf";
              });
            },
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    selectedFile.isEmpty ? 'Drag & drop your CV here' : selectedFile,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'or click to browse',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'supported formats: PDF, DOC, DOCX',
                    style: TextStyle(color: AppColors.textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info Badges matching Figma
          _buildInfoBanner(
            icon: Icons.verified_user_outlined,
            color: AppColors.success,
            text: 'Your CV information will only be used to provide job recommendations skill match results .',
          ),
          const SizedBox(height: 12),
          _buildInfoBanner(
            icon: Icons.info_outline,
            color: AppColors.primary,
            text: 'Your CV will be analysed to identify your skills , education,work experience, projects and certifications.',
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: widget.onNext,
            child: const Text('Analyses MY CV'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                selectedFile = "";
              });
            },
            child: const Text('Upload Another CV'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
