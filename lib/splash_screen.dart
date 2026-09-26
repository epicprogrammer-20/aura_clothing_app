import 'package:auraclothing_app/onboarding_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<String> _letters = ['A', 'U', 'R', 'A'];

  // Each letter gets its own staggered slice of the controller's timeline,
  // so they jump in sequence rather than all at once.
  late final List<Animation<double>> _jumpAnimations;
  late final List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _jumpAnimations = List.generate(_letters.length, (index) {
      final start = index * 0.15;
      final end = start + 0.5;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 60.0, end: -24.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: -24.0, end: 0.0)
              .chain(CurveTween(curve: Curves.bounceOut)),
          weight: 50,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.linear),
        ),
      );
    });

    _fadeAnimations = List.generate(_letters.length, (index) {
      final start = index * 0.15;
      final end = (start + 0.25).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeIn),
      );
    });

    _controller.forward();

    // Navigate to onboarding after a delay — unchanged from before.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_letters.length, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, _jumpAnimations[index].value),
                    child: child,
                  ),
                );
              },
              child: Text(
                _letters[index],
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                  letterSpacing: 4,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}