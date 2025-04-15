import 'package:flutter/material.dart';
import 'vinyl_home_page.dart';

void main() {
  runApp(const SpinTrackerApp());
}

class SpinTrackerApp extends StatefulWidget {
  const SpinTrackerApp({super.key});

  static _SpinTrackerAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_SpinTrackerAppState>();
  }

  @override
  State<SpinTrackerApp> createState() => _SpinTrackerAppState();
}

class _SpinTrackerAppState extends State<SpinTrackerApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spin Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromARGB(255, 255, 0, 0),
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 40, 0, 30),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color.fromARGB(255, 40, 0, 30),
        ),
      ),
      themeMode: _themeMode,
      home: const VinylHomePage(),
    );
  }
}
