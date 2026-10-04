import 'package:auraclothing_app/auth_service.dart';
import 'package:auraclothing_app/home_screen.dart';
import 'package:auraclothing_app/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // The Lottie is 2.2s long; we leave the splash exactly when it ends.
  static const Duration _splashDuration = Duration(milliseconds: 2200);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Load the saved login state while the animation plays, and wait for
    // whichever takes longer so the splash never cuts short.
    await Future.wait([
      AuthService.instance.load(),
      Future.delayed(_splashDuration),
    ]);

    if (!mounted) return;

    final Widget next = AuthService.instance.isLoggedIn
        ? const HomeScreen()
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = (screenWidth * 0.75).clamp(200.0, 420.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: logoWidth,
          child: Lottie.asset(
            'assets/aura/aura_logo_bounce.json',
            repeat: false,
            fit: BoxFit.contain,
            // If the animation ever fails to load, fall back to the static logo.
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/aura_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
