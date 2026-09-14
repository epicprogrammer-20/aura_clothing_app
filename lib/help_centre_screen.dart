import 'package:flutter/material.dart';

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  // MOCK DATA — replace with real FAQ/support content once available.
  static final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I track my order?',
      'answer':
      'Go to Profile > Order History to see the status of all your orders.',
    },
    {
      'question': 'What is your return policy?',
      'answer':
      'Items can be returned within 30 days of delivery, unworn and with tags attached.',
    },
    {
      'question': 'How do I link my Instagram or Facebook?',
      'answer':
      'Go to Profile and tap the edit icon next to your linked accounts section.',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'Email us at support@aura.app and we\'ll get back to you within 24 hours.',
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
          'Help Centre',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}