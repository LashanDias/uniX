import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../widgets/app_back_button.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({
    super.key,
    required this.recruiterId,
    required this.contactEmail,
    required this.onPublish,
  });

  final String recruiterId;
  final String contactEmail;
  final Future<void> Function(JobItem) onPublish;

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _requirements = TextEditingController();
  late final _contact = TextEditingController(text: widget.contactEmail);
  String _type = 'Full-time';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _company,
      _location,
      _description,
      _requirements,
      _contact,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onPublish(
        JobItem(
          id: '',
          title: _title.text.trim(),
          company: _company.text.trim(),
          location: _location.text.trim(),
          type: _type,
          description: _description.text.trim(),
          requirements: _requirements.text.trim(),
          contactEmail: _contact.text.trim().toLowerCase(),
          recruiterId: widget.recruiterId,
          matchPercentage: 0,
          logoUrl: '',
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not publish the vacancy. Check your connection and recruiter access, then try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    int limit = 200,
    String? hint,
    bool email = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: lines,
      maxLength: limit,
      keyboardType: email
          ? TextInputType.emailAddress
          : (lines > 1 ? TextInputType.multiline : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: lines > 1,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Enter $label.';
        if (email && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Enter a valid contact email.';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Post a vacancy'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Tell students about the role and what you are looking for.',
                  ),
                  const SizedBox(height: 24),
                  _field(_title, 'Job title'),
                  _field(_company, 'Company'),
                  _field(
                    _location,
                    'Location',
                    hint: 'Colombo / Remote / Hybrid',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Job type'),
                    items:
                        const [
                              'Full-time',
                              'Part-time',
                              'Internship',
                              'Contract',
                            ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 24),
                  _field(
                    _description,
                    'Job description',
                    lines: 4,
                    limit: 5000,
                    hint: 'Responsibilities and what the role involves',
                  ),
                  _field(
                    _requirements,
                    'Requirements',
                    lines: 5,
                    limit: 5000,
                    hint: 'Skills, qualifications and experience required',
                  ),
                  _field(
                    _contact,
                    'Application email',
                    email: true,
                    limit: 254,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _publish,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish),
                    label: Text(_saving ? 'Publishing...' : 'Publish vacancy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
