import 'package:flutter/material.dart';
import 'vinyl_home_page.dart';

void main() {
  runApp(const VinylCheckerApp());
}

class VinylCheckerApp extends StatelessWidget {
  const VinylCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinyl Checker',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
      ),
      home: const VinylHomePage(),
    );
  }
}
