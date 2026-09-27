import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'FIND YOUR STYLE',
      'description':
      'Discover looks curated just for you, refreshed every single day.',
      'image': 'assets/images/splashscreen/splash1.png',
    },
    {
      'title': 'PICK THE BEST',
      'description':
      'Compare, shortlist, and choose from thousands of hand-picked pieces.',
      'image': 'assets/images/splashscreen/splash2.png',
    },
    {
      'title': 'CHOOSE YOUR LOOK',
      'description':
      'Build outfits that feel like you — bold, simple, or somewhere in between.',
      'image': 'assets/images/splashscreen/splash1.png',
    },
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
    );
  }

  void _onNextPressed() {
    if (_isLastPage) {
      _goToHome();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.height < 700;
    final isTablet = size.width > 600;

    final contentMaxWidth = isTablet ? 480.0 : size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Image.asset(
                _pages[index]['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                ),
              );
            },
          ),

          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: _goToHome,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 0 : 32.0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey<int>(_currentPage),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _pages[_currentPage]['title']!,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 24 : 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 14),
                            Text(
                              _pages[_currentPage]['description']!,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: isSmallScreen ? 13 : 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white.withValues(alpha: 0.35),
                        expansionFactor: 3,
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 20 : 32),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 0 : 32.0,
                        vertical: isSmallScreen ? 14 : 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentPage + 1} / ${_pages.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: 56,
                            width: _isLastPage
                                ? contentMaxWidth * 0.55
                                : 56,
                            child: ElevatedButton(
                              onPressed: _onNextPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.zero,
                                elevation: 6,
                                shadowColor: Colors.black.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _isLastPage
                                    ? Row(
                                  key: const ValueKey('getStarted'),
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'GET STARTED',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                  ],
                                )
                                    : const Icon(
                                  Icons.arrow_forward,
                                  key: ValueKey('arrow'),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}