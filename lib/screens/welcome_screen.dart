import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Color palette based on wireframe (grayscale)
  static const Color primaryDark = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // App branding at top-left
              const Text(
                'Nestora',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                ),
              ),
              const Spacer(),
              // Main heading
              const Text(
                'Your Property Companion',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Subheading
              Text(
                'Over 100 homes waiting for you',
                style: TextStyle(
                  fontSize: 16,
                  color: mediumGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              // Get Started button
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: CustomButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(),
                      ),
                    );
                  },
                  backgroundColor: primaryDark,
                  borderRadius: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

