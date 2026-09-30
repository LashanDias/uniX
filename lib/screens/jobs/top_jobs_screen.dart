import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../services/ai/ai_agent.dart';
import '../../services/ai/market_tools.dart';
import '../../services/job_service.dart';
import 'job_listing_card.dart';

class TopJobsScreen extends StatelessWidget {
  final VoidCallback onPrev;
  final Stream<List<JobItem>>? jobsStream;

  const TopJobsScreen({super.key, required this.onPrev, this.jobsStream});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: onPrev,
              ),
              const Expanded(
                child: Text(
                  'Available Vacancies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 4, 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top jobs for you,\nCool! 🎉',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Explore vacancies posted\nby recruiters',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/jobs_robot.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<JobItem>>(
            stream: jobsStream ?? JobService.watchJobs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Unable to load vacancies. Check your connection and try again.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Text('No vacancies have been posted yet.');
              }
              return Column(
                children: [
                  for (final job in snapshot.data!) JobListingCard(job: job),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/ai_sparkle.jfif',
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Not finding the right job? Let our AI understand what you\'re looking for and find better matches for you',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _showAiHelp(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(78, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('+ Ask AI', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/micro_gigs'),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text(
                    'Micro-Gigs ⚡',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/career_passport'),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text(
                    'Passport 🏆',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAiHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final controller = TextEditingController();
        // One agent per opened chat, so the conversation keeps its memory for
        // as long as the sheet is open and starts clean next time. Career
        // advice leads, then the campus tools, so "what is the variance
        // formula" still works from inside the career chat.
        final agent = AiAgent(
          tools: [const CareerTool(), ...AiAgent.defaultTools()],
        );
        final messages = <Map<String, String>>[
          {
            'sender': 'ai',
            'text':
                'How can AI help you today? Tell me what kind of job you want.',
          },
        ];

        return StatefulBuilder(
          builder: (context, setSheetState) {
            var isLoading = false;

            Future<void> sendMessage() async {
              final text = controller.text.trim();
              if (text.isEmpty || isLoading) return;
              controller.clear();
              setSheetState(() {
                messages.add({'sender': 'user', 'text': text});
                isLoading = true;
              });
              final reply = await _generateAiReply(agent, text);
              if (!sheetContext.mounted) return;
              setSheetState(() {
                isLoading = false;
                messages.add({'sender': 'ai', 'text': reply});
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Job Assistant',
                      style: TextStyle(
                        color: Color(0xFF023E8A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isUser = message['sender'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF023E8A)
                                    : const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                message['text']!,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Gemini is thinking...'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => sendMessage(),
                            decoration: InputDecoration(
                              hintText: 'Ask about jobs, skills, or CVs...',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: sendMessage,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF023E8A),
                          ),
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _generateAiReply(AiAgent agent, String userMessage) async {
    try {
      final reply = await agent.send(userMessage);
      return reply.text;
    } catch (_) {
      return 'I could not reach the assistant. Please try again.';
    }
  }
}
