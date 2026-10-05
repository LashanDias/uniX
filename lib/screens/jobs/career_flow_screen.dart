import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/career_analysis.dart';
import '../../services/recruitment_documents.dart';
import '../../services/recruitment_store.dart';
import '../../services/local_career_ai.dart';
import 'recruitment_workspace_screen.dart';
import 'top_jobs_screen.dart';

class CareerFlowScreen extends StatefulWidget {
  const CareerFlowScreen({
    super.key,
    required this.accountId,
    this.profileName = '',
    this.profileEmail = '',
    this.pickDocument,
  });
  final String accountId, profileName, profileEmail;
  final Future<RecruitmentDocument?> Function()? pickDocument;
  @override
  State<CareerFlowScreen> createState() => _CareerFlowScreenState();
}

class _CareerFlowScreenState extends State<CareerFlowScreen> {
  final _store = RecruitmentStore();
  final _text = TextEditingController();
  final _scroll = ScrollController(keepScrollOffset: false);
  List<Map<String, dynamic>> _jobs = [];
  List<CareerMatch> _matches = [];
  CareerProfile? _profile;
  String _name = '', _filter = 'All', _sort = 'Best match';
  String? _selectedId, _error;
  int _step = 0;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cv = await _store.loadCv(widget.accountId);
      await _store.addSampleRequirements();
      final jobs = await _store.requirements();
      if (!mounted) return;
      setState(() {
        _text.text = '${cv['text'] ?? ''}';
        _name = '${cv['name'] ?? ''}';
        _jobs = jobs;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not read local documents. You can still upload a CV.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(int step) {
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final doc = await (widget.pickDocument ?? RecruitmentDocuments.pick)();
      if (!mounted || doc == null) return;
      setState(() {
        _name = doc.name;
        _text.text = doc.text;
        _profile = null;
        _matches = [];
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not read document: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyse() async {
    if (_text.text.trim().isEmpty || _text.text.length > 100000) {
      setState(
        () => _error = 'Upload or paste a CV with 1–100,000 characters.',
      );
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = CareerProfile.parse(_text.text);
      await _store.saveCv(
        widget.accountId,
        _name.isEmpty ? 'Pasted CV' : _name,
        profile.text,
      );
      final jobs = await _store.requirements();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _jobs = jobs;
        _recalculate();
      });
      _go(1);
    } catch (e) {
      if (mounted) setState(() => _error = 'Analysis could not finish: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _recalculate() {
    if (_profile == null) return;
    _matches = CareerAnalysis.rank(_profile!, _jobs);
    if (!_matches.any((m) => m.id == _selectedId)) {
      _selectedId = _matches.firstOrNull?.id;
    }
  }

  Future<void> _samples() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _store.addSampleRequirements();
      final jobs = await _store.requirements();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _recalculate();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not add sample requirements: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requirements() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RecruitmentWorkspaceScreen(
          accountId: widget.accountId,
          profileName: widget.profileName,
          profileEmail: widget.profileEmail,
        ),
      ),
    );
    try {
      final jobs = await _store.requirements();
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _recalculate();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not refresh requirements. Try opening the workspace again.',
        );
      }
    }
  }

  CareerMatch? get _selected =>
      _matches.where((m) => m.id == _selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            key: ValueKey(_step),
            controller: _scroll,
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _busy
                        ? null
                        : () {
                            if (_step > 0) {
                              _go(_step - 1);
                            } else {
                              Navigator.maybePop(context);
                            }
                          },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0)
                      Container(width: 20, height: 1, color: AppColors.primary),
                    Semantics(
                      label: 'Step ${i + 1} of 4',
                      selected: _step == i,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: i <= _step
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        child: Text(
                          i < _step ? '✓' : '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: i <= _step
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ...switch (_step) {
                0 => _upload(),
                1 => _extracted(),
                2 => _skillMatch(),
                _ => _rankedJobs(),
              },
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _title(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget _button(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: FilledButton(
      onPressed: _busy ? null : action,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(label),
    ),
  );
  Widget _card(Widget child, {Color color = Colors.white}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Material(color: Colors.transparent, child: child),
  );
  Widget _banner(String title, String subtitle) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Image.asset('assets/images/ai_robot.png', width: 85, height: 110),
      ],
    ),
  );

  List<Widget> _upload() => [
    _title('Upload your CV'),
    const Text(
      'Discover jobs and internships that match your skills, education and experience.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
    const SizedBox(height: 28),
    OutlinedButton(
      onPressed: _busy ? null : _pick,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
        backgroundColor: const Color(0xFFF3F5FF),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_upload_outlined, size: 48),
          const SizedBox(height: 12),
          Text(_name.isEmpty ? 'Click to browse your CV' : _name),
          const SizedBox(height: 8),
          const Text(
            'PDF, DOCX or TXT · up to 5 MB',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    _card(
      const Text(
        'Your CV stays in this browser. Document extraction and matching run locally.',
      ),
      color: const Color(0xFFF0F8F4),
    ),
    ExpansionTile(
      title: const Text('Review or paste CV text'),
      children: [
        TextField(
          controller: _text,
          minLines: 6,
          maxLines: 14,
          maxLength: 100000,
          decoration: const InputDecoration(
            hintText:
                'Paste your CV here. Include headings such as Education, Skills, Projects and Experience.',
          ),
        ),
      ],
    ),
    Wrap(
      spacing: 8,
      children: [
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _name = 'Sample student CV';
                    _text.text = sampleCareerCv;
                  });
                },
          child: const Text('Use sample CV'),
        ),
        TextButton(
          onPressed: _busy ? null : _pick,
          child: const Text('Upload another CV'),
        ),
      ],
    ),
    _button('Analyse my CV', _analyse),
    _title('HR job requirements'),
    Text(
      '${_jobs.length} requirements saved on this device. Use these to test CV matching, or browse current vacancies.',
    ),
    Wrap(
      spacing: 8,
      children: [
        OutlinedButton(
          onPressed: _busy ? null : _samples,
          child: const Text('Add sample HR requirements'),
        ),
        TextButton(
          onPressed: _busy ? null : _requirements,
          child: const Text('Open requirements workspace'),
        ),
      ],
    ),
    TextButton(
      onPressed: () => Navigator.pushNamed(context, '/recruiter'),
      child: const Text('HR manager? Open recruiter workspace'),
    ),
    TextButton(
      onPressed: () => Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: TopJobsScreen(onPrev: () => Navigator.pop(context)),
            ),
          ),
        ),
      ),
      child: const Text('Browse live vacancies'),
    ),
  ];

  List<Widget> _extracted() => [
    _title('CV Analysis'),
    const Text(
      'Review the information extracted from your document before matching.',
    ),
    const SizedBox(height: 16),
    _banner(
      'Your CV is ready',
      'Skills, education, experience, projects and certifications — from your document.',
    ),
    for (final section in _profile!.sections.entries)
      _card(
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 10),
          leading: Icon(switch (section.key) {
            'Education' => Icons.school_outlined,
            'Certifications' => Icons.workspace_premium_outlined,
            'Projects' => Icons.folder_special_outlined,
            'Experience' => Icons.work_outline,
            _ => Icons.description_outlined,
          }, color: AppColors.primary),
          title: Text(
            section.key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            section.value.isEmpty
                ? 'Not identified — review CV text'
                : section.value.first,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                section.value.isEmpty
                    ? 'No section found. You can add a heading in the CV text editor.'
                    : section.value.join('\n'),
              ),
            ),
          ],
        ),
      ),
    const Text(
      'Local extraction groups text by section headings. You can correct the text if your document uses a different layout.',
      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
    TextButton(onPressed: () => _go(0), child: const Text('Edit CV text')),
    _button('Continue to skill match', () => _go(2)),
  ];

  Widget _ring(int? score) => SizedBox(
    width: 70,
    height: 70,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 66,
          height: 66,
          child: CircularProgressIndicator(
            value: score == null ? 0 : score / 100,
            strokeWidth: 5,
            color: const Color(0xFF00854A),
            backgroundColor: const Color(0xFFE9F3ED),
          ),
        ),
        Text(
          score == null ? 'N/A' : '$score%\nMatch',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  List<Widget> _noRequirements() => [
    _card(const Text('Add HR requirements to compare your CV with a role.')),
    _button('Add sample HR requirements', _samples),
    TextButton(
      onPressed: _requirements,
      child: const Text('Upload HR requirements'),
    ),
  ];

  List<Widget> _skillMatch() {
    final match = _selected;
    return [
      _title('Skill Match Analysis'),
      const Text('Compare your CV with the selected job requirements.'),
      const SizedBox(height: 18),
      if (match == null)
        ..._noRequirements()
      else ...[
        DropdownButtonFormField<String>(
          initialValue: match.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Compare with'),
          items: _matches
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    '${m.job['title']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) => setState(() => _selectedId = id),
        ),
        const SizedBox(height: 18),
        _card(
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Match',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.score == null
                          ? 'Not enough recognised requirements'
                          : '${match.skills.matchedSkills.length} of ${match.skills.requiredSkills.length} recognised skills found',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Local requirement coverage',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _ring(match.score),
            ],
          ),
        ),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Match Breakdown'),
              for (final entry in match.breakdown.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(width: 92, child: Text(entry.key)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (entry.value ?? 0) / 100,
                          color: entry.key == 'Skills'
                              ? Colors.deepPurple
                              : AppColors.success,
                          backgroundColor: AppColors.border,
                          minHeight: 5,
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          entry.value == null ? ' N/A' : ' ${entry.value}%',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Skills 70%; other specified criteria 10% each. N/A criteria are excluded. Experience uses explicit years under Experience. Missing evidence scores 0; this does not prove lack of ability.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _skillsCard(
          'Matched Skills',
          match.skills.matchedSkills,
          const Color(0xFFF0F9F3),
          'assets/images/skill_match_ads.png',
        ),
        _skillsCard(
          'Skills to Improve',
          match.skills.missingSkills,
          const Color(0xFFF3F1FF),
          'assets/images/skill_match_robot.jfif',
        ),
        _card(
          Text(CareerAnalysis.advice(match, 'improve')),
          color: AppColors.primaryLight,
        ),
        _button('See matching jobs', () => _go(3)),
      ],
    ];
  }

  Widget _skillsCard(
    String title,
    List<String> skills,
    Color color,
    String image,
  ) => _card(
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                skills.isEmpty ? 'None identified' : skills.join('\n'),
                style: const TextStyle(height: 1.7),
              ),
            ],
          ),
        ),
        Image.asset(image, width: 100, height: 150, fit: BoxFit.contain),
      ],
    ),
    color: color,
  );

  List<Widget> _rankedJobs() {
    final matches = _matches
        .where((m) => _filter == 'All' || m.job['type'] == _filter)
        .toList();
    if (_sort == 'Job title') {
      matches.sort(
        (a, b) => '${a.job['title']}'.compareTo('${b.job['title']}'),
      );
    }
    return [
      _banner('Top jobs for you', 'Based on your CV and requirement coverage'),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Filter'),
              items: [
                'All',
                'Internship',
                'Full-time',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => _filter = s!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort by'),
              items: [
                'Best match',
                'Job title',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => _sort = s!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const Text(
        'Sample HR posts are labelled. Scores change with your CV; they are not hiring predictions.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      if (_matches.isEmpty) ..._noRequirements(),
      if (_matches.isNotEmpty && matches.isEmpty)
        const Text('No jobs match this filter. Choose All to see every role.'),
      for (final match in matches)
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      '${match.job['company'] ?? 'HR'}'.substring(0, 1),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${match.job['title']}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${match.job['company']}'),
                        Text(
                          '${match.job['location'] ?? 'Location not specified'} · ${match.job['workMode'] ?? 'Work mode not specified'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ring(match.score),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text('${match.job['type'] ?? 'HR requirement'}')),
                  if (match.job['sample'] == true)
                    const Chip(label: Text('Sample HR post')),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedId = match.id);
                      _go(2);
                    },
                    child: const Text('View analysis'),
                  ),
                  FilledButton(
                    onPressed: () => _jobDetails(match),
                    child: Text(
                      match.job['sample'] == true ? 'View sample' : 'Apply now',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      if (_selected != null)
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Not finding the right job?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Get local guidance based on your CV and the selected role.',
              ),
              OutlinedButton.icon(
                onPressed: () => _ask(_selected!),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Ask AI'),
              ),
            ],
          ),
          color: const Color(0xFFF0EEFF),
        ),
      TextButton(
        onPressed: _requirements,
        child: const Text('Manage HR requirements'),
      ),
      TextButton(
        onPressed: () => _go(0),
        child: const Text('Upload another CV'),
      ),
    ];
  }

  void _jobDetails(CareerMatch match) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('${match.job['title']}'),
                Text('${match.job['company']}'),
                const SizedBox(height: 16),
                SelectableText('${match.job['text']}'),
                const SizedBox(height: 20),
                if (match.job['sample'] == true)
                  const Text(
                    'Example uploaded by Sample HR Manager for local testing. No application will be sent.',
                  )
                else if ('${match.job['contactEmail'] ?? ''}'.isNotEmpty) ...[
                  const Text('To apply, send your CV with this job title to:'),
                  SelectableText('${match.job['contactEmail']}'),
                ] else
                  const Text(
                    'This HR requirement has no application contact. Ask the recruiter to add one.',
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _ask(CareerMatch match) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CareerAssistant(match: match),
  );
}

class _CareerAssistant extends StatefulWidget {
  const _CareerAssistant({required this.match});
  final CareerMatch match;
  @override
  State<_CareerAssistant> createState() => _CareerAssistantState();
}

class _CareerAssistantState extends State<_CareerAssistant> {
  final _question = TextEditingController();
  String _answer = '';
  String _source = 'Uses local AI when available; otherwise offline guidance.';
  bool _busy = false;
  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    if (_busy || question.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _question.text = question;
    });
    final reply = await LocalCareerAi.ask(widget.match, question);
    if (!mounted) return;
    setState(() {
      _answer = reply.text;
      _source = reply.source;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local career assistant',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Text('For ${widget.match.job['title']}'),
            Text(
              _source,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final prompt in [
                  'Why this score?',
                  'What should I learn?',
                  'Interview preparation',
                ])
                  ActionChip(
                    label: Text(prompt),
                    onPressed: _busy ? null : () => _send(prompt),
                  ),
              ],
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_answer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SelectableText(_answer),
              ),
            TextField(
              controller: _question,
              maxLength: 500,
              onSubmitted: _send,
              decoration: InputDecoration(
                hintText: 'Ask about skills, scores or interviews',
                suffixIcon: IconButton(
                  tooltip: 'Send question',
                  onPressed: _busy ? null : () => _send(_question.text),
                  icon: const Icon(Icons.send),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
