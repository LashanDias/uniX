import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/restaurant.dart';
import '../../widgets/app_back_button.dart';
import '../../services/restaurant_catalog.dart';
import 'restaurant_widgets.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key, required this.onSave});
  final Future<void> Function(Restaurant) onSave;

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _MenuDraft {
  final name = TextEditingController();
  final price = TextEditingController();
  String category = 'Mains';
  bool vegetarian = false;
  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _hours = TextEditingController();
  final _description = TextEditingController();
  final _menu = [_MenuDraft()];
  String _category = 'Restaurant';
  String _photo = '';
  bool _sample = false;
  bool _saving = false;
  bool _picking = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _address, _phone, _hours, _description]) {
      controller.dispose();
    }
    for (final draft in _menu) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 1024 * 1024) {
        throw StateError('Choose a photo smaller than 1 MB.');
      }
      if (mounted) setState(() => _photo = base64Encode(bytes));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not read this photo. Please choose another image.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _picking || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final place = Restaurant(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      hours: _hours.text.trim(),
      description: _description.text.trim().isEmpty
          ? 'Added to your restaurant list.'
          : _description.text.trim(),
      photoBase64: _photo,
      sampleMenu: _sample,
      menu: _sample
          ? sampleRestaurantMenu(
              _category,
              hostel: _name.text.toLowerCase().contains('hostel'),
            )
          : _menu
                .map(
                  (item) => RestaurantFood(
                    name: item.name.text.trim(),
                    category: item.category,
                    price: double.parse(item.price.text.trim()),
                    vegetarian: item.vegetarian,
                  ),
                )
                .toList(),
    );
    try {
      await widget.onSave(place);
      if (mounted) Navigator.pop(context, place);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Could not save. Device storage may be full; try a smaller photo or try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int lines = 1,
    int limit = 200,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: lines,
      maxLength: limit,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
      ),
      validator: (value) =>
          required && (value?.trim().isEmpty ?? true) ? 'Enter $label.' : null,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: foodCanvas,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Add Restaurant'),
        backgroundColor: foodCanvas,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FoodNotice(
                      text:
                          'New restaurants, menus and photos are saved on this device. They are not published to other users.',
                    ),
                    const SizedBox(height: 24),
                    _field(
                      _name,
                      'Restaurant name',
                      required: true,
                      limit: 120,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['Restaurant', 'Café', 'Canteen']
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      _address,
                      'Address',
                      required: true,
                      lines: 2,
                      limit: 300,
                    ),
                    TextFormField(
                      controller: _phone,
                      enabled: !_saving,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        return !RegExp(
                                  r'^\+?[\d\s()\-]+$',
                                ).hasMatch(value.trim()) ||
                                digits.length < 7 ||
                                digits.length > 15
                            ? 'Enter a valid phone number.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _field(_hours, 'Opening hours (optional)'),
                    _field(
                      _description,
                      'About this place (optional)',
                      lines: 3,
                      limit: 1000,
                    ),
                    if (_photo.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RestaurantPhoto(photoBase64: _photo),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _photo = ''),
                        child: const Text('Remove photo'),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: _saving || _picking ? null : _pickPhoto,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        _picking ? 'Reading photo...' : 'Add photo (optional)',
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: foodInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use a sample menu'),
                      subtitle: const Text(
                        'Suggested dishes with clearly labelled estimated prices.',
                      ),
                      value: _sample,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _sample = value),
                    ),
                    if (!_sample) ...[
                      for (final (index, draft) in _menu.indexed)
                        _menuEditor(index, draft),
                      OutlinedButton.icon(
                        onPressed: _saving || _menu.length >= 30
                            ? null
                            : () => setState(() => _menu.add(_MenuDraft())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add menu item'),
                      ),
                    ],
                    const SizedBox(height: 24),
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving || _picking ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: foodAccent,
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.add_business_outlined),
                        label: Text(_saving ? 'Saving...' : 'Save restaurant'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _menuEditor(int index, _MenuDraft draft) => Container(
    key: ObjectKey(draft),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Menu item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_menu.length > 1)
              IconButton(
                tooltip: 'Remove menu item ${index + 1}',
                onPressed: _saving
                    ? null
                    : () {
                        setState(() => _menu.remove(draft));
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => draft.dispose(),
                        );
                      },
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _field(draft.name, 'Dish name', required: true, limit: 120),
        TextFormField(
          controller: draft.price,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price (LKR)'),
          validator: (value) {
            final price = double.tryParse(value?.trim() ?? '');
            return price == null ||
                    !price.isFinite ||
                    price <= 0 ||
                    price > 100000
                ? 'Enter a price between 0 and 100,000 LKR (greater than zero).'
                : null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: draft.category,
          decoration: const InputDecoration(labelText: 'Meal category'),
          items: ['Breakfast', 'Lunch', 'Dinner', 'Mains', 'Snacks', 'Drinks']
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
          onChanged: _saving
              ? null
              : (value) => setState(() => draft.category = value!),
        ),
        Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vegetarian'),
            value: draft.vegetarian,
            onChanged: _saving
                ? null
                : (value) => setState(() => draft.vegetarian = value!),
          ),
        ),
      ],
    ),
  );
}
