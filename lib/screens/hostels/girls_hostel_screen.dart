import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_back_button.dart';

class GirlsHostelScreen extends StatefulWidget {
  const GirlsHostelScreen({super.key});
  @override
  State<GirlsHostelScreen> createState() => _GirlsHostelScreenState();
}

class _GirlsHostelScreenState extends State<GirlsHostelScreen> {
  DateTimeRange? _dates;
  bool _checked = false;
  bool _saving = false;
  int _floor = 2;
  static const _floors = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
  ];
  String _date(DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);
  int get _nights => _dates == null
      ? 0
      : DateTime.utc(_dates!.end.year, _dates!.end.month, _dates!.end.day)
            .difference(
              DateTime.utc(
                _dates!.start.year,
                _dates!.start.month,
                _dates!.start.day,
              ),
            )
            .inDays;

  Future<void> _chooseDates() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final dates = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      initialDateRange: _dates,
      helpText: 'Select stay dates',
      saveText: 'Save',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: const DatePickerThemeData(
            rangePickerHeaderHeadlineStyle: TextStyle(fontSize: 18),
          ),
        ),
        child: child!,
      ),
    );
    if (dates == null || !mounted) return;
    setState(() {
      _dates = dates;
      _checked = false;
    });
  }

  Future<void> _saveRequest(String room) async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = prefs.getStringList('hostel.bookingDrafts.v1') ?? [];
      final draft = jsonEncode({
        'hostel': 'Girls Hostel • HUB 02',
        'room': room,
        'floor': _floors[_floor],
        'checkIn': _dates!.start.toIso8601String(),
        'checkOut': _dates!.end.toIso8601String(),
        'status': 'Draft',
      });
      if (!await prefs.setStringList('hostel.bookingDrafts.v1', [
        ...drafts,
        draft,
      ])) {
        throw StateError('Save failed');
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking draft saved'),
          content: Text(
            'Room $room\n${_date(_dates!.start)} – ${_date(_dates!.end)}\n$_nights nights\n\nSaved on this device. No room has been reserved and no payment has been taken.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your draft. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Girls Hostel'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAF1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.apartment, size: 48, color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'HUB 02 • Girls Hostel',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('60+ rooms for students • 2, 4 and 6-sharing rooms'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select stay dates',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _chooseDates,
                icon: const Icon(Icons.date_range),
                label: Text(
                  _dates == null
                      ? 'Choose your dates'
                      : '${_date(_dates!.start)} – ${_date(_dates!.end)}',
                ),
              ),
              if (_dates != null)
                Text('Your stay: $_nights nights • Maximum 90 nights'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _dates == null || _saving
                    ? null
                    : () {
                        if (_nights < 1 || _nights > 90) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Choose a stay between 1 and 90 nights.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _checked = true);
                      },
                child: const Text('Check availability'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Room details below are from your supplied reference. Live availability and booking are not connected.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose a floor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  4,
                  (index) => ChoiceChip(
                    label: Text(_floors[index]),
                    selected: _floor == index,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _floor = index),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('${_floors[_floor]} • 2, 4 and 6-sharing rooms for girls'),
              const SizedBox(height: 20),
              if (!_checked)
                const Text(
                  'Select your dates and check availability to view room details.',
                )
              else if (_floor != 2)
                const Text(
                  'Room details for this floor are pending. Select 2nd Floor to view the reference rooms.',
                )
              else ...[
                const Text(
                  'Reference rooms • Availability needs confirmation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final room in [
                  ('0207', 2),
                  ('0208', 3),
                  ('0209', 1),
                  ('0210', 2),
                ])
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 20,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                'Room ${room.$1}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'LKR 9,500.00 / room',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${room.$2} ${room.$2 == 1 ? 'bed' : 'beds'} shown in reference • 4 guests',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '100% deposit • Non-refundable • Maximum 90 nights',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pricing period and current availability must be confirmed with the hostel.',
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _saving
                                ? null
                                : () => _saveRequest(room.$1),
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: const Text('Save booking draft'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
