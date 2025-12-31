import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Ensure Flutter is initialized before Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://isscokydhntpfypibnti.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlzc2Nva3lkaG50cGZ5cGlibnRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MDYwNzYsImV4cCI6MjA3NDk4MjA3Nn0.d0ioDvNuU89FMR8huMbbg0qe00-AXUrsshcicd8N1CA',
  );

  runApp(const MyApp());
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

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
      home: const AuthStateWrapper(),
    );
  }
}

class AuthStateWrapper extends StatefulWidget {
  const AuthStateWrapper({super.key});

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // User signed in, navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // User signed out, navigate to welcome
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check initial auth state
    final session = supabase.auth.currentSession;
    if (session != null) {
      // User is authenticated, show home screen
      return const HomeScreen();
    } else {
      // User is not authenticated, show welcome screen
      return const WelcomeScreen();
    }
  }
}
