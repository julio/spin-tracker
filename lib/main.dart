import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'vinyl_home_page.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Remove the iOS system message filter to see all logs
    print('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace:\n${record.stackTrace}');
    }
  });

  runApp(const VinylCheckerApp());
}

class VinylCheckerApp extends StatelessWidget {
  const VinylCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), // Slightly lighter than black
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E), // Matching app bar color
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const VinylHomePage(),
    );
  }
}
