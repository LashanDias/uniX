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
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onPrev,
                    icon: const Icon(Icons.arrow_back, size: 20),
                    tooltip: 'Back',
                  ),
                ),
                const Text(
                  'Skill Match Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'We compare your skills with the job requirements to calculate your match score.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8F4),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: Colors.amber,
                              size: 22,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Top 10%\nof applicants',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF008647),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Match',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Excellent match',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF008647),
                              ),
                            ),
                            Text(
                              'you are a strong match for this opportunity',
                              style: TextStyle(fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: .94,
                                strokeWidth: 5,
                                color: Color(0xFF008647),
                                backgroundColor: Color(0xFFE7F2EB),
                              ),
                            ),
                            Text(
                              '94%\nMatch',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Match Breakdown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _progress('Skill Match', .78, const Color(0xFF913CE4)),
                      _progress('Education Match', 1, const Color(0xFF2FCB7B)),
                      _progress(
                        'Experience Match',
                        .84,
                        const Color(0xFFD8E85A),
                      ),
                      _progress('Location Match', 1, const Color(0xFF2FCB7B)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _skills(
                  title: 'Matched Skills',
                  color: const Color(0xFF008020),
                  background: const Color(0xFFF1F9F4),
                  skills:
                      'Python\nSQL\nPower BI\nData Analysis\nCommunication\nProblem Solving',
                  image: 'assets/images/skill_match_ads.png',
                ),
                const SizedBox(height: 16),
                _skills(
                  title: 'Skills to Improve',
                  color: AppColors.primary,
                  background: const Color(0xFFF3F1FF),
                  skills:
                      'Advanced SQL\nStatistics\nAzure\nData Visualization\nCloud computing',
                  image: 'assets/images/skill_match_robot.jfif',
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Career Tip',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Learning Advanced SQL and Statistics can significantly increase match score and open more opportunities.',
                              style: TextStyle(fontSize: 10, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(double.infinity, 42),
                    ),
                    child: const Text(
                      'Analyses MY CV',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE1E1E1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 2,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _progress(String label, double value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            color: color,
            backgroundColor: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 9, color: Color(0xFF2FCB7B)),
          ),
        ),
      ],
    ),
  );

  Widget _skills({
    required String title,
    required Color color,
    required Color background,
    required String skills,
    required String image,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                skills,
                style: const TextStyle(fontSize: 13, height: 1.55),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Image.asset(image, height: 150, fit: BoxFit.contain),
            ),
          ],
        ),
      ],
    ),
  );
}
