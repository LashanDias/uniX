import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../services/girls_hostel_inventory.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/safe_network_image.dart';

class GirlsHostelScreen extends StatefulWidget {
  const GirlsHostelScreen({super.key});
  @override
  State<GirlsHostelScreen> createState() => _GirlsHostelScreenState();
}

class _GirlsHostelScreenState extends State<GirlsHostelScreen> {
  DateTimeRange? _dates;
  bool _checked = false;
  bool _saving = false;
  int _floor = 0;

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

  Future<void> _saveRequest(HostelRoom room) async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final drafts = prefs.getStringList('hostel.bookingDrafts.v1') ?? [];
      final draft = jsonEncode({
        'hostel': 'Girls Hostel • HUB 02',
        'room': room.number,
        'floor': room.floorLabel,
        'sharing': room.sharing,
        'pricePerMonth': room.monthlyPrice,
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
            'Room ${room.number} • ${room.typeLabel}\n'
            '${room.floorLabel}\n'
            '${_date(_dates!.start)} – ${_date(_dates!.end)}\n'
            '$_nights nights • LKR ${room.monthlyPrice} / month\n\n'
            'Saved on this device. No room has been reserved and no payment '
            'has been taken.',
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

  void _checkAvailability() {
    if (_nights < 1 || _nights > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a stay between 1 and 90 nights.')),
      );
      return;
    }
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = GirlsHostelInventory.roomsOn(_floor);
    final free = rooms.where((room) => !room.isFull).length;
    return Scaffold(
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
                const _BuildingHeader(),
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
                if (_dates != null) ...[
                  const SizedBox(height: 8),
                  Text('Your stay: $_nights nights • Maximum 90 nights'),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _dates == null || _saving
                      ? null
                      : _checkAvailability,
                  child: const Text('Check availability'),
                ),
                const SizedBox(height: 24),
                const _PricingTable(),
                const SizedBox(height: 24),
                const Text(
                  'Choose a floor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (
                      var index = 0;
                      index < GirlsHostelInventory.floors.length;
                      index++
                    )
                      ChoiceChip(
                        label: Text(GirlsHostelInventory.floors[index]),
                        selected: _floor == index,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _floor = index),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${GirlsHostelInventory.floors[_floor]} • '
                  '${GirlsHostelInventory.roomsPerFloor} rooms '
                  '(${GirlsHostelInventory.sixSharingPerFloor} six-sharing, '
                  '${GirlsHostelInventory.fourSharingPerFloor} four-sharing)',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                // Rooms are listed straight away. Hiding them behind the date
                // picker meant opening the hostel showed an empty screen,
                // which reads as the feature being broken. Dates are still
                // needed to save a booking, not to look.
                ...[
                  Text(
                    '$free of ${rooms.length} rooms have free beds',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (!_checked) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Choose your dates above to book one of these rooms.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  for (final room in rooms)
                    _RoomCard(
                      room: room,
                      nights: _nights,
                      saving: _saving,
                      canBook: _checked,
                      onSave: () => _saveRequest(room),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildingHeader extends StatelessWidget {
  const _BuildingHeader();

  /// Photo of the building, shown above the summary.
  static const photoUrl =
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5'
      '?auto=format&fit=crop&w=900&q=80';

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFFFEAF1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SafeNetworkImage(
          url: photoUrl,
          height: 150,
          placeholderIcon: Icons.apartment,
          placeholderLabel: 'HUB 02',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HUB 02 • Girls Hostel',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Spacious building with ${GirlsHostelInventory.totalRooms} rooms '
                'reserved for students, across '
                '${GirlsHostelInventory.floors.length} floors.',
              ),
              const SizedBox(height: 4),
              const Text('4-sharing and 6-sharing rooms for girls.'),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Monthly, weekly and daily rates for each room type.
class _PricingTable extends StatelessWidget {
  const _PricingTable();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Room rates',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        'Prices are per room, not per bed.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      // Wrap so the two cards sit side by side on a tablet and stack on a
      // phone instead of overflowing.
      LayoutBuilder(
        builder: (context, constraints) {
          final twoUp = constraints.maxWidth > 520;
          final cardWidth = twoUp
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final sharing in [4, 6])
                SizedBox(
                  width: cardWidth,
                  child: _RateCard(sharing: sharing),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.sharing});

  final int sharing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$sharing-sharing',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _rate('Per month', GirlsHostelInventory.monthlyPrice(sharing)),
        _rate('Per week', GirlsHostelInventory.weeklyPrice(sharing)),
        _rate('Per day', GirlsHostelInventory.dailyPrice(sharing)),
      ],
    ),
  );

  Widget _rate(String label, int amount) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'LKR $amount',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.nights,
    required this.saving,
    required this.canBook,
    required this.onSave,
  });

  final HostelRoom room;
  final int nights;
  final bool saving;

  /// False until dates are chosen, since a booking needs them.
  final bool canBook;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: room.isFull ? AppColors.border : AppColors.primary,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: room.isFull ? AppColors.chipBg : AppColors.badgeGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              room.bedsLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: room.isFull
                    ? AppColors.textSecondary
                    : AppColors.badgeGreenText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Wrap keeps the room number and price on one line when there is
          // room and stacks them on a narrow phone.
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                room.number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LKR ${room.monthlyPrice} / month',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${room.typeLabel} • ${room.floorLabel} • sleeps ${room.sharing}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            '100% deposit • Non-refundable • Maximum 90 nights',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: room.isFull
                ? OutlinedButton(
                    onPressed: null,
                    child: const Text('Fully booked'),
                  )
                : ElevatedButton.icon(
                    onPressed: saving || !canBook ? null : onSave,
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: Text(canBook ? 'Book now' : 'Choose dates to book'),
                  ),
          ),
        ],
      ),
    ),
  );
}
