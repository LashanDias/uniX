import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'upload_cv_screen.dart';
import 'ai_cv_analysis_screen.dart';
import 'skill_match_screen.dart';
import 'top_jobs_screen.dart';

class JobsHomeScreen extends StatefulWidget {
  const JobsHomeScreen({super.key});

  @override
  State<JobsHomeScreen> createState() => _JobsHomeScreenState();
}

class _JobsHomeScreenState extends State<JobsHomeScreen> {
  int currentStep = 1;

  void _goToNextStep() {
    if (currentStep < 4) {
      setState(() => currentStep++);
    }
  }

  void _goToPrevStep() {
    if (currentStep > 1) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator (1 - 2 - 3 - 4) matching Figma
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  int stepNum = index + 1;
                  bool isCurrent = currentStep == stepNum;
                  bool isCompleted = currentStep > stepNum;

                  return Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isCurrent || isCompleted) ? AppColors.primary : AppColors.chipBg,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    color: (isCurrent || isCompleted) ? Colors.white : AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      if (index < 3)
                        Container(
                          width: 24,
                          height: 2,
                          color: isCompleted ? AppColors.primary : AppColors.border,
                        ),
                    ],
                  );
                }),
              ),
            ),

            // Step Content
            Expanded(
              child: _buildCurrentStepView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (currentStep) {
      case 1:
        return UploadCvScreen(onNext: _goToNextStep);
      case 2:
        return AiCvAnalysisScreen(onNext: _goToNextStep, onPrev: _goToPrevStep);
      case 3:
        return SkillMatchScreen(onNext: _goToNextStep, onPrev: _goToPrevStep);
      case 4:
        return TopJobsScreen(onPrev: _goToPrevStep);
      default:
        return UploadCvScreen(onNext: _goToNextStep);
    }
  }
}
