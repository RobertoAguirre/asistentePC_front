import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistente PIPC',
      theme: ThemeData(
        primaryColor: const Color(0xFF003B87),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003B87),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: const Color(0xFF0D47A1),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
