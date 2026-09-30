import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/reference_sheets.dart';
import '../../widgets/app_back_button.dart';

/// Browse the formula reference sheets.
class ReferenceSheetsScreen extends StatefulWidget {
  const ReferenceSheetsScreen({super.key, this.sheets});

  final List<ReferenceSheet>? sheets;

  @override
  State<ReferenceSheetsScreen> createState() => _ReferenceSheetsScreenState();
}

class _ReferenceSheetsScreenState extends State<ReferenceSheetsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.sheets ?? ReferenceSheets.all;
    final visible = all.where((sheet) => sheet.matches(_query)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Formula sheets'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search formulas, e.g. variance',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One-page summaries to revise from. Tap a sheet to open it.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No sheet matches that search.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  for (final sheet in visible)
                    _SheetTile(
                      sheet: sheet,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReferenceSheetScreen(sheet: sheet),
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
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.sheet, required this.onTap});

  final ReferenceSheet sheet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cardBg,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.functions, color: AppColors.primary),
      ),
      title: Text(
        sheet.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${sheet.modulePath} · ${sheet.entries.length} formulas',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

/// A single formula sheet, laid out like a printed revision poster.
class ReferenceSheetScreen extends StatelessWidget {
  const ReferenceSheetScreen({super.key, required this.sheet});

  final ReferenceSheet sheet;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFDF7),
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Text(sheet.title),
      backgroundColor: const Color(0xFFFFFDF7),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              Text(
                sheet.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A5F),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sheet.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sheet.summary,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Two columns on a tablet, one on a phone: a formula card is
              // unreadable if it is squeezed narrower than this.
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoUp = constraints.maxWidth > 560;
                  final width = twoUp
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (var index = 0;
                          index < sheet.entries.length;
                          index++)
                        SizedBox(
                          width: width,
                          child: _FormulaCard(
                            number: index + 1,
                            entry: sheet.entries[index],
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (sheet.quickReminder.isNotEmpty) ...[
                const SizedBox(height: 18),
                _QuickReminder(pairs: sheet.quickReminder),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.number, required this.entry});

  final int number;
  final FormulaEntry entry;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: entry.colour.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: entry.colour.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: entry.colour.withValues(alpha: 0.18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: entry.colour,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final formula in entry.formulas.entries) ...[
                if (formula.key.isNotEmpty) ...[
                  Text(
                    formula.key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: entry.colour,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    formula.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: entry.colour.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'When to use it?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final line in entry.whenToUse)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickReminder extends StatelessWidget {
  const _QuickReminder({required this.pairs});

  final Map<String, String> pairs;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF9C3),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFDE68A)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: Color(0xFFCA8A04),
            ),
            const SizedBox(width: 8),
            const Text(
              'Quick Reminder',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF854D0E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final pair in pairs.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  pair.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Text('  →  ', style: TextStyle(fontSize: 13)),
                Text(
                  pair.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
