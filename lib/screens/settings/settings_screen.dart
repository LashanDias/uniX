import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../services/app_settings.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_back_button.dart';

/// App settings: notification switches, plus account actions.
///
/// The app had no settings screen at all, so there was no way to turn
/// notifications off.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AppSettings.load();
  }

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your password to sign back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthService.signOut();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: const AppBackButton(),
      title: const Text('Settings'),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ValueListenableBuilder<Map<String, bool>>(
            valueListenable: AppSettings.values,
            builder: (context, values, _) {
              final notificationsOn = AppSettings.isOn('notifications');
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _SectionHeading('Notifications'),
                  for (final toggle in AppSettings.toggles)
                    _ToggleTile(
                      toggle: toggle,
                      value: AppSettings.isOn(toggle.key),
                      // Every other switch is dimmed while the master is off,
                      // so the screen shows why nothing will arrive.
                      enabled: toggle.master || notificationsOn,
                      onChanged: (value) =>
                          AppSettings.set(toggle.key, value),
                    ),
                  if (!notificationsOn)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Notifications are off, so nothing below will be sent.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _SectionHeading('Account'),
                  _LinkTile(
                    icon: Icons.person_outline,
                    title: 'Edit my profile',
                    onTap: () =>
                        Navigator.pushNamed(context, '/edit_profile'),
                  ),
                  _LinkTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'View notifications',
                    onTap: () =>
                        Navigator.pushNamed(context, '/notifications'),
                  ),
                  _LinkTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send feedback',
                    onTap: () => Navigator.pushNamed(context, '/feedback'),
                  ),
                  _LinkTile(
                    icon: Icons.logout,
                    title: 'Sign out',
                    danger: true,
                    onTap: _signOut,
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeading('About'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'UNIX Mobile · SLTC Research University\n'
                      'Settings are saved on this device.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.toggle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final SettingToggle toggle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: toggle.master ? AppColors.primary : AppColors.border,
      ),
    ),
    child: SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(
        toggle.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: enabled ? AppColors.textPrimary : AppColors.textLight,
        ),
      ),
      subtitle: Text(
        toggle.description,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ),
  );
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cardBg,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      leading: Icon(
        icon,
        color: danger ? AppColors.error : AppColors.primary,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: danger ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    ),
  );
}
