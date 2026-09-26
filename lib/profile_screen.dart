import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'user_model.dart';
import 'order_history_screen.dart';
import 'help_centre_screen.dart';
import 'privacy_policy_screen.dart';
import 'settings_screen.dart';
import 'auth_service.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserModel _user = mockCurrentUser;

  void _shareInvite() {
    Share.share(
      'Come check out AURA — the app I use to shop and share my favorite fits! '
          'Download it here: https://aura.app/invite',
      subject: 'Join me on AURA',
    );
  }

  void _logout() {
    AuthService.instance.logout();
  }

  void _editLinkedAccounts() {
    final instagramController =
    TextEditingController(text: _user.instagramHandle ?? '');
    final facebookController =
    TextEditingController(text: _user.facebookUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Linked accounts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram username',
                  prefixText: '@',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook profile URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _user.instagramHandle = instagramController.text.trim().isEmpty
                          ? null
                          : instagramController.text.trim();
                      _user.facebookUrl = facebookController.text.trim().isEmpty
                          ? null
                          : facebookController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: AuthService.instance,
        builder: (context, _) {
          if (!AuthService.instance.isLoggedIn) {
            return _buildLoggedOutState();
          }
          return _buildProfileContent();
        },
      ),
    );
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              'Log in to view your profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See your orders, saved items, and account details once you\'re signed in.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'LOG IN',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.black,
                child: Text(
                  _user.initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user.bio,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  children: [
                    if (_user.instagramHandle != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.instagram,
                              size: 14, color: Colors.black87),
                          const SizedBox(width: 6),
                          Text('@${_user.instagramHandle}',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    if (_user.facebookUrl != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          FaIcon(FontAwesomeIcons.facebook,
                              size: 14, color: Colors.black87),
                          SizedBox(width: 6),
                          Text('Facebook linked', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    if (_user.instagramHandle == null && _user.facebookUrl == null)
                      Text(
                        'No linked accounts',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.black),
                onPressed: _editLinkedAccounts,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: Colors.grey[200], thickness: 6),

        _menuRow(
          icon: Icons.receipt_long_outlined,
          label: 'My Orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
            );
          },
        ),
        _menuRow(
          icon: Icons.help_outline,
          label: 'Help Centre',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCentreScreen()),
            );
          },
        ),
        _menuRow(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            );
          },
        ),
        _menuRow(
          icon: Icons.person_add_alt_outlined,
          label: 'Invite a Friend',
          onTap: _shareInvite,
        ),
        _menuRow(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        _menuRow(
          icon: Icons.logout,
          label: 'Log Out',
          onTap: _logout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDestructive ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isDestructive)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}