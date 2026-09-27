import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'app_colors.dart';
import 'cart_service.dart';
import 'currency_service.dart';
import 'receipt_pdf_builder.dart';

class ReceiptScreen extends StatefulWidget {
  final ReceiptData data;

  const ReceiptScreen({super.key, required this.data});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late final Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = buildAuraReceiptPdf(widget.data);
  }

  Future<void> _preview() async {
    final bytes = await _pdfFuture;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            title: const Text('Receipt Preview',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: PdfPreview(
            build: (format) async => bytes,
            allowPrinting: false,
            allowSharing: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrDownload() async {
    final bytes = await _pdfFuture;
    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: widget.data.fileName,
    );
  }

  Future<void> _share() async {
    final bytes = await _pdfFuture;
    if (!mounted) return;
    await Printing.sharePdf(bytes: bytes, filename: widget.data.fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: const Text('E-Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _ReceiptCard(data: widget.data),
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              icon: Icons.visibility_outlined,
              label: 'Preview',
              onTap: _preview,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: Icons.download_outlined,
              label: 'Save PDF',
              onTap: _saveOrDownload,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              icon: Icons.ios_share,
              label: 'Share',
              onTap: _share,
              filled: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: filled ? Colors.white : AppColors.accent),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : AppColors.accent,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: filled ? AppColors.accent : Colors.white,
          side: BorderSide(color: AppColors.accent.withValues(alpha: filled ? 0 : 1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptData data;

  const _ReceiptCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurrencyService.instance,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final d = data;
    final dt = d.paidAt;
    final currency = CurrencyService.instance;
    final money = currency.format;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo only — it already renders the AURA wordmark, so no
          // separate "AURA" text sits next to it. No PAID badge either.
          Image.asset(
            'assets/images/aura_logo.png',
            height: 26,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          const Text('defined by simplicity',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _meta('ORDER ID', d.orderId)),
              Expanded(child: _meta('DATE', dateStr)),
              Expanded(child: _meta('TIME', timeStr)),
            ],
          ),
          const SizedBox(height: 14),
          _meta('PAYMENT METHOD', d.paymentMethodLabel),
          const SizedBox(height: 20),
          const Text(
            'CUSTOMER & SHIPPING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(d.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(d.customerEmail, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(d.customerPhone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Text(d.shippingAddress, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          const Text(
            'ITEMS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in d.items) _itemRow(item, money),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _summaryRow('Subtotal', money(d.subtotal)),
          _summaryRow('Shipping', d.shipping == 0 ? 'Free' : money(d.shipping)),
          if (d.promoCode != null && d.promoDiscount > 0)
            _summaryRow('Promo (${d.promoCode})', '-${money(d.promoDiscount)}'),
          if (d.pointsDiscount > 0)
            _summaryRow('Aura Points redeemed', '-${money(d.pointsDiscount)}'),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _summaryRow('Total Paid', money(d.total), bold: true),
          if (d.pointsEarned > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You earned ${d.pointsEarned} Aura Points on this order',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Refunds are only available within 72 hours of purchase.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9.5, color: Colors.grey.shade500, letterSpacing: 0.6)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _itemRow(CartItem item, String Function(double) money) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              item.product.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 40,
                height: 40,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text('${item.size} · Qty ${item.quantity}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(money(item.total),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? Colors.black : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.accent : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
