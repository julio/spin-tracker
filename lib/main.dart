import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'vinyl_home_page.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // Filter out iOS system messages
    if (!record.message.contains('Failed to index parameter type') &&
        !record.message.contains('Preferred localizations')) {
      print('${record.level.name}: ${record.time}: ${record.message}');
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
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      home: const VinylHomePage(),
    );
  }
}
