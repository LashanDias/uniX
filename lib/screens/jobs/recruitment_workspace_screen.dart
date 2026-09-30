import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/ai_hero_banner.dart';
import '../../services/recruitment_documents.dart';
import '../../services/recruitment_store.dart';
import '../../services/cv_comparison_service.dart';
import '../../widgets/app_back_button.dart';

class RecruitmentWorkspaceScreen extends StatefulWidget {
  const RecruitmentWorkspaceScreen({
    super.key,
    required this.accountId,
    this.recruiterMode = false,
    this.profileName = '',
    this.profileEmail = '',
    this.onPublishVacancy,
  });
  final String accountId;
  final bool recruiterMode;
  final String profileName;
  final String profileEmail;
  final VoidCallback? onPublishVacancy;

  @override
  State<RecruitmentWorkspaceScreen> createState() =>
      _RecruitmentWorkspaceScreenState();
}

class _RecruitmentWorkspaceScreenState
    extends State<RecruitmentWorkspaceScreen> {
  final _store = RecruitmentStore();
  final _cv = TextEditingController();
  final _requirements = TextEditingController();
  final _role = TextEditingController();
  final _company = TextEditingController();
  List<Map<String, dynamic>> _savedRequirements = [];
  String? _selectedId;
  String _cvName = '';
  String _requirementName = '';
  int _tab = 0;
  bool _busy = true;
  String? _message;
  CvComparison? _comparison;
  String? _aiSummary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_cv, _requirements, _role, _company]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cv = await _store.loadCv(widget.accountId);
      final requirements = await _store.requirements();
      if (!mounted) return;
      setState(() {
        _cv.text = cv['text'] as String? ?? '';
        _cvName = cv['name'] as String? ?? '';
        _savedRequirements = requirements;
        if (requirements.isNotEmpty) _select(requirements.first);
      });
    } catch (error) {
      // Naming the cause matters: this fires whenever device storage cannot
      // be read, and a message with no reason gave nothing to act on.
      if (mounted) {
        setState(
          () => _message =
              'Could not load saved documents ($error). '
              'You can still upload or paste text below.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _select(Map<String, dynamic> entry) {
    _selectedId = entry['id'] as String;
    _requirements.text = entry['text'] as String;
    _role.text = entry['title'] as String;
    _company.text = entry['company'] as String;
    _requirementName = entry['fileName'] as String? ?? '';
    _comparison = null;
    _aiSummary = null;
  }

  Future<void> _import(bool cv) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final document = await RecruitmentDocuments.pick();
      if (!mounted || document == null) return;
      setState(() {
        if (cv) {
          _cv.text = document.text;
          _cvName = document.name;
        } else {
          _requirements.text = document.text;
          _requirementName = document.name;
        }
        _comparison = null;
        _aiSummary = null;
        _message =
            'Document read. Review the extracted text before saving or comparing.';
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is FormatException
              ? error.message
              : 'Could not read the document. Try a text-based PDF, DOCX or TXT file, or paste its text.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(bool cv) async {
    if (_busy) return;
    if ((!cv &&
            (_role.text.trim().length < 2 ||
                _role.text.trim().length > 150 ||
                _company.text.trim().length < 2 ||
                _company.text.trim().length > 150)) ||
        (cv ? _cv.text : _requirements.text).trim().length > 100000) {
      setState(
        () => _message =
            'Use 2–150 characters for job title and company, and at most 100,000 characters for document text.',
      );
      return;
    }

    if ((cv ? _cv.text : _requirements.text).trim().isEmpty ||
        (!cv && (_role.text.trim().isEmpty || _company.text.trim().isEmpty))) {
      setState(
        () => _message = cv
            ? 'Add your CV text first.'
            : 'Enter a job title, company and requirements.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (cv) {
        await _store.saveCv(
          widget.accountId,
          _cvName.isEmpty ? 'Pasted CV' : _cvName,
          _cv.text.trim(),
        );
      } else {
        final ownsSelected = _savedRequirements.any(
          (entry) =>
              entry['id'] == _selectedId &&
              entry['ownerId'] == widget.accountId,
        );
        final id = ownsSelected
            ? _selectedId!
            : 'req-${DateTime.now().microsecondsSinceEpoch}';
        await _store.saveRequirements({
          'id': id,
          'ownerId': widget.accountId,
          'title': _role.text.trim(),
          'company': _company.text.trim(),
          'text': _requirements.text.trim(),
          'fileName': _requirementName,
          'contactName': widget.profileName,
          'contactEmail': widget.profileEmail,
        });
        final saved = await _store.requirements();
        if (!mounted) return;
        _savedRequirements = saved;
        _selectedId = id;
      }
      if (mounted) {
        setState(
          () => _message = cv
              ? 'CV saved on this device.'
              : 'HR requirements saved on this device.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not save. Your entered text is still here; please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _compare() {
    try {
      final result = CvComparisonService.compare(_cv.text, _requirements.text);
      setState(() {
        _comparison = result;
        _aiSummary = null;
        _message = null;
        _tab = 2;
      });
    } on FormatException catch (error) {
      setState(() => _message = error.message);
    }
  }

  Future<void> _aiReview() async {
    if (_cv.text.trim().isEmpty || _requirements.text.trim().isEmpty) {
      _compare();
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final summary = await CvComparisonService.aiReview(
        _cv.text,
        _requirements.text,
      );
      if (mounted) setState(() => _aiSummary = summary);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'AI review is unavailable. Your local comparison is still available.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changed(String _) => setState(() {
    _comparison = null;
    _aiSummary = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Text(
        widget.recruiterMode ? 'HR recruitment workspace' : 'CV & job matching',
      ),
      actions: [
        IconButton(
          tooltip: 'My profile',
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AiHeroBanner(
                  title: widget.recruiterMode
                      ? 'Find the skills your team needs.'
                      : 'Your CV. Real requirements.',
                  subtitle:
                      'Upload documents, review the text and compare '
                      'the student CV with the HR brief.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Local workspace • saved on this device. Requirements are not yet shared across devices.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                if (!widget.recruiterMode)
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/recruiter'),
                    icon: const Icon(Icons.badge_outlined),
                    label: const Text('HR manager? Open recruiter workspace'),
                  ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, label) in [
                      widget.recruiterMode ? 'HR profile' : 'My CV',
                      'HR requirements',
                      'Compare CV',
                    ].indexed)
                      ChoiceChip(
                        label: Text(label),
                        selected: _tab == index,
                        onSelected: (_) => setState(() => _tab = index),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_busy) const LinearProgressIndicator(),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_message!),
                  ),
                if (_tab == 0 && widget.recruiterMode) ...[
                  const Icon(
                    Icons.badge_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.profileName.isEmpty
                        ? 'HR manager'
                        : widget.profileName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(widget.profileEmail),
                  const SizedBox(height: 12),
                  const Text(
                    'This workspace uses your existing account profile.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View / edit my profile'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => setState(() => _tab = 1),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload HR requirements'),
                  ),
                  if (widget.onPublishVacancy != null)
                    TextButton(
                      onPressed: widget.onPublishVacancy,
                      child: const Text('Open vacancy publishing form'),
                    ),
                ],
                if (_tab == 0 && !widget.recruiterMode) ..._cvEditor(),
                if (_tab == 1) ..._requirementsEditor(),
                if (_tab == 2) ...[
                  ..._cvEditor(),
                  const Divider(height: 32),
                  Text(
                    _role.text.isEmpty
                        ? 'HR requirements'
                        : '${_role.text} · ${_company.text}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _requirements.text.isEmpty
                        ? 'Select or paste requirements in the HR requirements tab.'
                        : _requirements.text,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _tab = 1),
                    child: const Text('Choose / review requirements'),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _compare,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Compare CV with requirements'),
                  ),
                  const SizedBox(height: 20),
                  if (_comparison != null) ..._results(_comparison!),
                  const SizedBox(height: 16),
                  if (CvComparisonService.aiEnabled) ...[
                    const Text(
                      'AI review sends the CV text and HR requirements to the configured analysis service.',
                    ),
                    OutlinedButton(
                      onPressed: _busy ? null : _aiReview,
                      child: const Text('Request AI review'),
                    ),
                  ] else
                    const Text(
                      'AI review is not connected. The comparison above is a local skill-keyword check, not an AI hiring decision.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (_aiSummary != null) SelectableText(_aiSummary!),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _cvEditor() => [
    const Text(
      'Student CV',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _busy ? null : () => _import(true),
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload student CV'),
    ),
    const Text(
      'PDF, DOCX or TXT · up to 5 MB. You can also paste text below.',
      style: TextStyle(fontSize: 12),
    ),
    if (_cvName.isNotEmpty)
      Padding(padding: const EdgeInsets.only(top: 8), child: Text(_cvName)),
    const SizedBox(height: 12),
    TextField(
      controller: _cv,
      enabled: !_busy,
      minLines: 6,
      maxLines: 12,
      maxLength: 100000,
      onChanged: _changed,
      decoration: const InputDecoration(
        labelText: 'CV text',
        alignLabelWithHint: true,
      ),
    ),
    Wrap(
      spacing: 12,
      children: [
        TextButton(
          onPressed: _busy ? null : () => _save(true),
          child: const Text('Save CV on this device'),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  try {
                    await _store.removeCv(widget.accountId);
                    if (mounted) {
                      setState(() {
                        _cv.clear();
                        _cvName = '';
                        _comparison = null;
                        _aiSummary = null;
                      });
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => _message =
                            'Could not remove the saved CV. Please try again.',
                      );
                    }
                  }
                },
          child: const Text('Remove CV'),
        ),
      ],
    ),
    if (_tab != 2)
      FilledButton(
        onPressed: () => setState(() => _tab = 1),
        child: const Text('Next: HR requirements'),
      ),
  ];

  List<Widget> _requirementsEditor() => [
    const Text(
      'HR job requirements',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 12),
    if (_savedRequirements.isNotEmpty)
      DropdownButtonFormField<String>(
        key: ValueKey(_selectedId),
        initialValue: _selectedId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Saved requirements on this device',
        ),
        items: _savedRequirements
            .map(
              (entry) => DropdownMenuItem(
                value: entry['id'] as String,
                child: Text(
                  '${entry['title']} · ${entry['company']}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _busy
            ? null
            : (id) => setState(
                () => _select(
                  _savedRequirements.firstWhere((entry) => entry['id'] == id),
                ),
              ),
      ),
    const SizedBox(height: 12),
    TextField(
      controller: _role,
      enabled: !_busy,
      onChanged: _changed,
      decoration: const InputDecoration(labelText: 'Job title'),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _company,
      enabled: !_busy,
      onChanged: _changed,
      decoration: const InputDecoration(labelText: 'Company'),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _busy ? null : () => _import(false),
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload requirements document'),
    ),
    const Text('PDF, DOCX or TXT · up to 5 MB', style: TextStyle(fontSize: 12)),
    if (_requirementName.isNotEmpty) Text(_requirementName),
    const SizedBox(height: 12),
    TextField(
      controller: _requirements,
      enabled: !_busy,
      minLines: 6,
      maxLines: 12,
      maxLength: 100000,
      onChanged: _changed,
      decoration: const InputDecoration(
        labelText: 'HR requirements text',
        alignLabelWithHint: true,
      ),
    ),
    if (widget.recruiterMode) ...[
      FilledButton(
        onPressed: _busy ? null : () => _save(false),
        child: const Text('Save HR requirements'),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(() {
                _selectedId = null;
                _requirements.clear();
                _role.clear();
                _company.clear();
                _requirementName = '';
                _comparison = null;
                _aiSummary = null;
              }),
        child: const Text('Start a new requirements brief'),
      ),
    ],
    const SizedBox(height: 12),
    OutlinedButton(
      onPressed: () => setState(() => _tab = 2),
      child: const Text('Next: compare student CV'),
    ),
  ];

  List<Widget> _results(CvComparison result) => [
    Text(
      result.coverage == null
          ? 'No recognised skill keywords in this brief'
          : '${result.coverage}% listed-skill coverage',
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 8),
    const Text(
      'This checks named skills only. It does not verify experience, qualifications or suitability; review the full documents.',
    ),
    const SizedBox(height: 16),
    const Text('Found in CV', style: TextStyle(fontWeight: FontWeight.bold)),
    Text(
      result.matchedSkills.isEmpty
          ? 'No matching skill keywords found.'
          : result.matchedSkills.join(', '),
    ),
    const SizedBox(height: 12),
    const Text(
      'Not mentioned in CV',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    Text(
      result.missingSkills.isEmpty
          ? 'None among the recognised requirements.'
          : result.missingSkills.join(', '),
    ),
  ];
}
