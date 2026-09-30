import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AiMarketAssistantScreen extends StatefulWidget {
  const AiMarketAssistantScreen({super.key});

  @override
  State<AiMarketAssistantScreen> createState() => _AiMarketAssistantScreenState();
}

class _AiMarketAssistantScreenState extends State<AiMarketAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [
    {
      'sender': 'ai',
      'text': 'Hi I\'m your AI market assistant , how can I help you today ?',
    }
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({'sender': 'user', 'text': text});
    });
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        messages.add({
          'sender': 'ai',
          'text': 'Based on market analysis, the suggested price for this item is Rs. 42,000 - 45,000.',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI market Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  const _AssistantBanner(),
                  const SizedBox(height: 18),
                  ...messages.map((msg) {
                    bool isAi = msg['sender'] == 'ai';
                    return Align(
                      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isAi ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isAi ? AppColors.textPrimary : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),

                  // Preset Suggestion Buttons matching Figma image
                  _buildOptionTile(
                    icon: Icons.sell_outlined,
                    title: 'suggest price',
                    subtitle: 'Get price suggestion for you',
                    onTap: () => _sendMessage('Suggest price'),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    icon: Icons.edit_note_outlined,
                    title: 'Write Description',
                    subtitle: 'AI will write a description for you',
                    onTap: () => _sendMessage('Write Description'),
                  ),
                  const SizedBox(height: 12),
                  _buildOptionTile(
                    icon: Icons.manage_search_outlined,
                    title: 'Find similar items',
                    subtitle: 'Find similar products',
                    onTap: () => _sendMessage('Find similar items'),
                  ),
                ],
              ),
            ),

            // Input Bar at bottom matching Figma
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Robot hero at the top of the assistant, matching the CV matching screen.
class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    // The robot is dropped on a narrow phone, where it would squeeze the
    // heading into a column of single words.
    child: LayoutBuilder(
      builder: (context, constraints) {
        const copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selling something? Ask me.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'I can suggest a fair price, write your description and find '
              'similar items on campus.',
              style: TextStyle(color: Colors.white, height: 1.45),
            ),
          ],
        );
        if (constraints.maxWidth < 420) return copy;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(child: copy),
            const SizedBox(width: 12),
            Image.asset(
              'assets/images/ai_bot.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              // A missing asset must not break the banner.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
        );
      },
    ),
  );
}
