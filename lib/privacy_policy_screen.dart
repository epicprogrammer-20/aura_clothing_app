import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // MOCK COPY — replace with the real privacy policy before launch.
  static const List<Map<String, String>> _sections = [
    {
      'title': '1. Types of Data We Collect',
      'body':
      'We collect information you give us directly, such as your name, '
          'email address, shipping address, and payment details when you '
          'create an account or place an order. We also collect information '
          'about how you use the app, including the products you view, the '
          'items you save, and the pages you visit, so we can keep AURA '
          'running smoothly and improve it over time.',
    },
    {
      'title': '2. Use of Your Personal Data',
      'body':
      'Your data is used to process orders, provide customer support, and '
          'personalize your shopping experience. If you choose to link your '
          'Instagram or Facebook account, we use that connection only to '
          'display your handle on posts you choose to share — we never post '
          'on your behalf without your action. We may also use your contact '
          'details to send order updates and, where you\'ve opted in, '
          'product announcements.',
    },
    {
      'title': '3. Disclosure of Your Personal Data',
      'body':
      'We do not sell your personal data. We share only what\'s necessary '
          'with trusted service providers — such as payment processors and '
          'delivery couriers — so they can complete the services you\'ve '
          'requested. We may also disclose information if required by law, '
          'or to protect the rights, property, or safety of AURA, our users, '
          'or the public.',
    },
    {
      'title': '4. Data Retention',
      'body':
      'We keep your account and order information for as long as your '
          'account is active or as needed to provide you with our services. '
          'You can request deletion of your account and associated data at '
          'any time from Settings, or by contacting our support team.',
    },
    {
      'title': '5. Your Choices',
      'body':
      'You can review and update your personal information, unlink your '
          'Instagram or Facebook account, or change your notification '
          'preferences at any time from your Profile. You can also reach '
          'out to us through the Help Centre if you have questions about '
          'your data.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 22),
        itemBuilder: (context, index) {
          final section = _sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section['title']!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section['body']!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}