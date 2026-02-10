import 'package:flutter/material.dart';
import '../main.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 22),
      onPressed: () {
        SpinTrackerApp.of(context)?.toggleTheme();
      },
      tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
