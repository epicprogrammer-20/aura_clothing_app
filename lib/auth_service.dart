import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signin_screen.dart';

class AuthService extends ChangeNotifier {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _loggedInKey = 'aura_is_logged_in';

  bool isLoggedIn = false;

  /// Restores the saved login state. Called once from the splash screen so
  /// users who were logged in when they closed the app skip straight to Home.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
      notifyListeners();
    } catch (_) {
      isLoggedIn = false;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, isLoggedIn);
    } catch (_) {
      // Persistence is best-effort; the in-memory state still works.
    }
  }

  void login() {
    isLoggedIn = true;
    _save();
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    _save();
    notifyListeners();
  }
}

// Tracks the currently-shown toast so a repeated call replaces it cleanly
// instead of stacking multiple overlapping timers.
OverlayEntry? _activeLoginToast;

bool requireLogin(BuildContext context, {String message = 'Log in to continue'}) {
  if (AuthService.instance.isLoggedIn) return true;

  _showLoginToast(context, message);
  return false;
}

void _showLoginToast(BuildContext context, String message) {
  // Remove any toast already on screen so this one starts with a fresh,
  // full-length timer rather than competing with a stale one.
  _activeLoginToast?.remove();
  _activeLoginToast = null;

  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _LoginToast(
      message: message,
      onLogin: () {
        entry.remove();
        _activeLoginToast = null;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      },
    ),
  );

  _activeLoginToast = entry;
  overlay.insert(entry);

  // Fixed 2.5s auto-dismiss, independent of how many times this was
  // triggered — always removes itself on its own schedule.
  Future.delayed(const Duration(milliseconds: 2500), () {
    if (_activeLoginToast == entry) {
      entry.remove();
      _activeLoginToast = null;
    }
  });
}

class _LoginToast extends StatefulWidget {
  final String message;
  final VoidCallback onLogin;

  const _LoginToast({required this.message, required this.onLogin});

  @override
  State<_LoginToast> createState() => _LoginToastState();
}

class _LoginToastState extends State<_LoginToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onLogin,
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}