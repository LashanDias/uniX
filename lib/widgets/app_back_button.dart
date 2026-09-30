import 'package:flutter/material.dart';

/// Returns to the previous page, or Home when this is the first route.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back),
    onPressed: () async {
      final navigator = Navigator.of(context);
      if (!await navigator.maybePop() && context.mounted) {
        navigator.pushReplacementNamed('/main');
      }
    },
  );
}
