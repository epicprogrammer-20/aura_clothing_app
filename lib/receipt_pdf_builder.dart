import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cart_service.dart';
import 'currency_service.dart';

/// Everything the PDF (and the on-screen receipt card) needs to render.
/// Built once, right when an order succeeds, from values captured before
/// the cart is cleared — see CheckoutScreen._placeOrder.
class ReceiptData {
  final String orderId;
  final DateTime paidAt;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final String? promoCode;
  final double promoDiscount;
  final double pointsDiscount;
  final double total;
  final int pointsEarned;
  final String paymentMethodLabel;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;

  const ReceiptData({
    required this.orderId,
    required this.paidAt,
    required this.items,
    required this.subtotal,
    required this.shipping,
    this.promoCode,
    this.promoDiscount = 0,
    required this.pointsDiscount,
    required this.total,
    required this.pointsEarned,
    required this.paymentMethodLabel,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
  });

  String get fileName => 'Aura_Receipt_$orderId.pdf';
}

// Strict black and white theme — the PDF's own "accent" is just black.
const PdfColor _kAccent = PdfColors.black;

String _money(double v) => CurrencyService.instance.format(v);
String _pad2(int n) => n.toString().padLeft(2, '0');

String _colorName(Color c) {
  const map = {
    0xFF000000: 'Black',
    0xFFFFFFFF: 'White',
    0xFF1F6FEB: 'Blue',
    0xFF2E7D32: 'Green',
    0xFFE91E63: 'Pink',
  };
  return map[c.toARGB32()] ?? 'Selected';
}

Future<Uint8List> buildAuraReceiptPdf(ReceiptData data) async {
  final doc = pw.Document();
  final logoData = await rootBundle.load('assets/images/aura_logo.png');
  final logo = pw.MemoryImage(logoData.buffer.asUint8List());

  final d = data.paidAt;
  final dateStr = '${_pad2(d.day)}/${_pad2(d.month)}/${d.year}';
  final timeStr = '${_pad2(d.hour)}:${_pad2(d.minute)}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header — logo only (it already renders the AURA wordmark),
            // plus the tagline. No separate "AURA" text, no PAID badge.
            pw.Row(
              children: [
                pw.Image(logo, width: 84, height: 32, fit: pw.BoxFit.contain),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'defined by simplicity',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // Order meta
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _metaBlock('ORDER ID', data.orderId),
                _metaBlock('DATE', dateStr),
                _metaBlock('TIME', timeStr),
                _metaBlock('PAYMENT', data.paymentMethodLabel),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Text(
              'CUSTOMER & SHIPPING',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _kAccent,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(data.customerName, style: const pw.TextStyle(fontSize: 11)),
            pw.Text(data.customerEmail,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(data.customerPhone,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(data.shippingAddress,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 24),

            pw.Text(
              'ITEMS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _kAccent,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(1.6),
                3: pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
                    ),
                  ),
                  children: [
                    _th('Product'),
                    _th('Qty'),
                    _th('Price'),
                    _th('Total'),
                  ],
                ),
                for (final item in data.items)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text(
                          '${item.product.title}  ·  ${item.size} / ${_colorName(item.color)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text('${item.quantity}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text(_money(item.unitPrice),
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 6),
                        child: pw.Text(
                          _money(item.total),
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 240,
                child: pw.Column(
                  children: [
                    _summaryRow('Subtotal', _money(data.subtotal)),
                    _summaryRow(
                      'Shipping',
                      data.shipping == 0 ? 'Free' : _money(data.shipping),
                    ),
                    if (data.promoCode != null && data.promoDiscount > 0)
                      _summaryRow(
                        'Promo (${data.promoCode})',
                        '-${_money(data.promoDiscount)}',
                      ),
                    if (data.pointsDiscount > 0)
                      _summaryRow(
                        'Aura Points redeemed',
                        '-${_money(data.pointsDiscount)}',
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    _summaryRow('Total Paid', _money(data.total), bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),

            if (data.pointsEarned > 0)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'You earned ${data.pointsEarned} Aura Points on this order.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _kAccent,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text(
              'Refunds are only available within 72 hours of purchase.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Thank you for shopping with Aura.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _metaBlock(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey500,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    ],
  );
}

pw.Widget _th(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 6),
  child: pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey700,
    ),
  ),
);

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: bold ? 12 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bold ? 12 : 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: bold ? _kAccent : PdfColors.black,
          ),
        ),
      ],
    ),
  );
}
