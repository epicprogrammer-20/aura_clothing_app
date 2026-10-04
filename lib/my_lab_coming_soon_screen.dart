import 'package:flutter/material.dart';

/// Placeholder shown while My Lab is still being built.
/// When My Lab is ready, point the Home banner back at MyLabScreen
/// (see _buildMyLabBanner in home_screen.dart) and delete this file.
class MyLabComingSoonScreen extends StatelessWidget {
  const MyLabComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Lab',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.checkroom_outlined,
                    size: 38, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              const Text(
                'COMING SOON',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Mix and match tops, bottoms and accessories to build your own outfits. We\'re putting the finishing touches on it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, height: 1.5, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
