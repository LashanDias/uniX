import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../services/boarding_store.dart';
import '../../widgets/app_back_button.dart';

/// Boarding places near campus, with the ones students add themselves.
class BoardingScreen extends StatefulWidget {
  const BoardingScreen({
    super.key,
    this.store,
    this.category = BoardingCategory.boarding,
  });

  final BoardingStore? store;

  /// Which accommodation section to show.
  final BoardingCategory category;

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  late final BoardingStore _store = widget.store ?? BoardingStore();
  final _searchController = TextEditingController();

  List<BoardingPlace> _places = const [];
  bool _loading = true;
  bool _storageFailed = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _store.load(category: widget.category);
    if (!mounted) return;
    setState(() {
      _places = result.places;
      _storageFailed = result.storageFailed;
      _loading = false;
    });
  }

  Future<void> _openForm({BoardingPlace? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BoardingFormScreen(
          store: _store,
          existing: existing,
          category: widget.category,
        ),
      ),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Boarding place added.'
                  : 'Boarding place updated.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _remove(BoardingPlace place) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this place?'),
        content: Text('"${place.name}" will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _store.remove(place.id);
      await _load();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove this. Please retry.')),
      );
    }
  }

  /// Dials the place. A desktop browser usually cannot, so say so plainly
  /// and show the number to copy instead of failing silently.
  Future<void> _call(BoardingPlace place) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await launchUrl(place.phoneUrl)) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not start a call. ${place.phone}')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not start a call. ${place.phone}')),
      );
    }
  }

  Future<void> _openMap(BoardingPlace place) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await launchUrl(place.mapsUrl, mode: LaunchMode.externalApplication)) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open the map. ${place.address}')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open the map. ${place.address}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _places.where((place) => place.matches(_query)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(widget.category.label),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_home_outlined),
        label: Text(
          widget.category == BoardingCategory.annex
              ? 'Add annex'
              : 'Add boarding place',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search by name, type or address',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${visible.length} '
                        '${visible.length == 1 ? 'place' : 'places'} near campus',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Nearest first. Confirm price and availability with '
                        'the owner before paying anything.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (_storageFailed) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Places you added could not be loaded from this '
                          'device. The list below is still complete.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 40,
                                color: AppColors.textLight,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No boarding place matches that search.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        for (final place in visible)
                          _BoardingCard(
                            place: place,
                            onMap: () => _openMap(place),
                            onCall: () => _call(place),
                            onEdit: place.custom
                                ? () => _openForm(existing: place)
                                : null,
                            onRemove: place.custom
                                ? () => _remove(place)
                                : null,
                          ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _BoardingCard extends StatelessWidget {
  const _BoardingCard({
    required this.place,
    required this.onMap,
    required this.onCall,
    this.onEdit,
    this.onRemove,
  });

  final BoardingPlace place;
  final VoidCallback onMap;
  final VoidCallback onCall;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (place.rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text(
                    place.ratingLabel,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            _chip(place.kind),
            _chip(place.distanceLabel),
            if (place.monthlyPrice != null)
              _chip('LKR ${place.monthlyPrice} / month', highlight: true),
            if (place.hasPhone) _chip(place.phone),
            if (place.custom) _chip('Added by you', highlight: true),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                place.address,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (place.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '"${place.note}"',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onMap,
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Directions'),
            ),
            if (place.hasPhone)
              FilledButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Call now'),
              ),
            if (onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Update'),
              ),
            if (onRemove != null)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _chip(String label, {bool highlight = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: highlight ? AppColors.primaryLight : AppColors.chipBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: highlight ? AppColors.primary : AppColors.textSecondary,
      ),
    ),
  );
}

/// Form for adding or updating a boarding place.
class BoardingFormScreen extends StatefulWidget {
  const BoardingFormScreen({
    super.key,
    required this.store,
    this.existing,
    this.category = BoardingCategory.boarding,
  });

  final BoardingStore store;
  final BoardingPlace? existing;
  final BoardingCategory category;

  @override
  State<BoardingFormScreen> createState() => _BoardingFormScreenState();
}

class _BoardingFormScreenState extends State<BoardingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _address = TextEditingController(
    text: widget.existing?.address ?? '',
  );
  late final _distance = TextEditingController(
    text: widget.existing?.distanceKm.toString() ?? '',
  );
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _price = TextEditingController(
    text: widget.existing?.monthlyPrice?.toString() ?? '',
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late String _kind = widget.existing?.kind ?? BoardingStore.kinds.first;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _distance,
      _phone,
      _price,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final distance = double.tryParse(_distance.text.trim()) ?? 0;
      final price = int.tryParse(_price.text.trim());
      if (_isEdit) {
        await widget.store.update(
          widget.existing!.copyWith(
            name: _name.text.trim(),
            kind: _kind,
            address: _address.text.trim(),
            distanceKm: distance,
            phone: _phone.text.trim(),
            monthlyPrice: price,
            note: _note.text.trim(),
          ),
        );
      } else {
        await widget.store.add(
          BoardingPlace(
            id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
            name: _name.text.trim(),
            kind: _kind,
            address: _address.text.trim(),
            distanceKm: distance,
            phone: _phone.text.trim(),
            monthlyPrice: price,
            note: _note.text.trim(),
            category: widget.category,
            custom: true,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: Text(
        _isEdit
            ? 'Update ${widget.category.label.toLowerCase()}'
            : 'Add to ${widget.category.label}',
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: "Indika's Boarding House",
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter a name.' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final kind in BoardingStore.kinds)
                      DropdownMenuItem(value: kind, child: Text(kind)),
                  ],
                  onChanged: (value) => setState(() => _kind = value ?? _kind),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    hintText: '164, 11 Dekaduwala Road',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter an address.' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _distance,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Distance from campus in km *',
                    hintText: '0.55',
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null) return 'Enter a number, e.g. 0.55';
                    if (parsed < 0 || parsed > 100) {
                      return 'Enter a distance between 0 and 100 km.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly rent in LKR (optional)',
                    hintText: '9500',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    final parsed = int.tryParse(text);
                    if (parsed == null || parsed < 0) {
                      return 'Enter a whole number, or leave it empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '0112 100 500',
                  ),
                ),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    alignLabelWithHint: true,
                    hintText: 'Quiet, close to the bus stop, meals included...',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: Text(
                    _saving
                        ? 'Saving...'
                        : (_isEdit ? 'Save changes' : 'Add place'),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Saved on this device only. Check the place yourself before '
                  'paying a deposit.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
