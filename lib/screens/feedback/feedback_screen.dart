import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/feedback_service.dart';
import '../../widgets/app_back_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  String _category = 'Idea';
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a rating before sending.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FeedbackService.submit(
        category: _category,
        rating: _rating,
        message: _message.text,
      );
      if (!mounted) return;
      _message.clear();
      setState(() => _rating = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your feedback was sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : 'Could not send feedback. Check your connection and retry.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Send feedback'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help us improve UNIX',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Report a problem, share an idea, or tell us how the app is working for you.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Feedback type'),
                items: const [
                  DropdownMenuItem(value: 'Idea', child: Text('Idea')),
                  DropdownMenuItem(value: 'Bug report', child: Text('Bug report')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: _sending
                    ? null
                    : (value) {
                        if (value != null) setState(() => _category = value);
                      },
              ),
              const SizedBox(height: 22),
              const Text(
                'How would you rate the app?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                      onPressed: _sending
                          ? null
                          : () => setState(() => _rating = star),
                      icon: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 30,
                      ),
                    ),
                ],
              ),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _message,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your feedback',
                    hintText: 'Tell us what happened or what you would like to see.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => FeedbackService.validationError(
                    category: _category,
                    rating: _rating == 0 ? 1 : _rating,
                    message: value ?? '',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'Sending...' : 'Send feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
