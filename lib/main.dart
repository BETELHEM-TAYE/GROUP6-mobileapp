import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Color palette based on wireframe design
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryDark,
          primary: primaryDark,
          background: lightGray,
        ),
        scaffoldBackgroundColor: lightGray,
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
