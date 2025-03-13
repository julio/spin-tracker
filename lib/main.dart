import 'package:flutter/material.dart';
import 'vinyl_home_page.dart';

void main() {
  runApp(const VinylCheckerApp());
}

class VinylCheckerApp extends StatefulWidget {
  const VinylCheckerApp({super.key});

  static _VinylCheckerAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_VinylCheckerAppState>();
  }

  @override
  State<VinylCheckerApp> createState() => _VinylCheckerAppState();
}

class _VinylCheckerAppState extends State<VinylCheckerApp> {
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
      title: 'Vinyl Checker',
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
