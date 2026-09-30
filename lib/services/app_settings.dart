import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences, stored on the device.
///
/// A [ValueNotifier] so a screen can rebuild the moment a switch changes
/// rather than waiting for a reload.
class AppSettings {
  AppSettings._();

  static const _prefix = 'settings.v1.';

  /// Every toggle, with its key and default.
  static const toggles = <SettingToggle>[
    SettingToggle(
      key: 'notifications',
      title: 'Allow notifications',
      description: 'Turn this off to silence everything below.',
      defaultValue: true,
      master: true,
    ),
    SettingToggle(
      key: 'notify.jobs',
      title: 'Job matches',
      description: 'New vacancies and gigs that fit your profile.',
      defaultValue: true,
    ),
    SettingToggle(
      key: 'notify.marketplace',
      title: 'Marketplace',
      description: 'Replies about items you are buying or selling.',
      defaultValue: true,
    ),
    SettingToggle(
      key: 'notify.notices',
      title: 'Notice board',
      description: 'Campus announcements and event flyers.',
      defaultValue: true,
    ),
    SettingToggle(
      key: 'notify.lostFound',
      title: 'Lost & Found',
      description: 'Follow-ups on items you reported.',
      defaultValue: true,
    ),
    SettingToggle(
      key: 'notify.hostel',
      title: 'Hostel',
      description: 'Booking updates and warden announcements.',
      defaultValue: true,
    ),
  ];

  /// Current values, broadcast so screens rebuild on change.
  static final ValueNotifier<Map<String, bool>> values =
      ValueNotifier<Map<String, bool>>({
        for (final toggle in toggles) toggle.key: toggle.defaultValue,
      });

  /// Loads saved values. Falls back to defaults if storage is unavailable.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      values.value = {
        for (final toggle in toggles)
          toggle.key:
              prefs.getBool('$_prefix${toggle.key}') ?? toggle.defaultValue,
      };
    } catch (_) {
      // Keep the defaults; settings are a convenience, not a blocker.
    }
  }

  static bool isOn(String key) =>
      values.value[key] ??
      toggles.firstWhere((t) => t.key == key).defaultValue;

  /// True when [key] should actually fire: its own switch is on *and*
  /// notifications are enabled overall.
  static bool notifies(String key) => isOn('notifications') && isOn(key);

  static Future<void> set(String key, bool value) async {
    values.value = {...values.value, key: value};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$key', value);
    } catch (_) {
      // The in-memory value still applies for this session.
    }
  }
}

class SettingToggle {
  const SettingToggle({
    required this.key,
    required this.title,
    required this.description,
    required this.defaultValue,
    this.master = false,
  });

  final String key;
  final String title;
  final String description;
  final bool defaultValue;

  /// The master switch that disables the rest when off.
  final bool master;
}
