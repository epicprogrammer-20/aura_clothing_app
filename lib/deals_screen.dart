import 'dart:async';
import 'package:flutter/material.dart';
import 'deal_model.dart';
import 'product_detail_screen.dart';
import 'currency_service.dart';
import 'auth_service.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  late final Timer _timer;
  Duration _remaining = Duration.zero;
  late final DealModel _featuredDeal;

  @override
  void initState() {
    super.initState();
    _featuredDeal = mockDeals.first;
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final diff = _featuredDeal.endsAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
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
          'Deals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildBanner(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'All Deals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockDeals.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 14,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) => _DealCard(deal: mockDeals[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            // Placeholder image — swap for real banner art later.
            child: Image.network(
              _featuredDeal.product.imageUrl,
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.4),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, _, _) => Container(color: Colors.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${_featuredDeal.discountPercent.toInt()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Season Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Up to ${_featuredDeal.discountPercent.toInt()}% off selected styles',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 15, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      'Ends in ${_formatDuration(_remaining)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: _featuredDeal.product),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: const Text(
                    'CHECK IT OUT',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatefulWidget {
  final DealModel deal;
  const _DealCard({required this.deal});

  @override
  State<_DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<_DealCard> {
  @override
  Widget build(BuildContext context) {
    final product = widget.deal.product;
    final deal = widget.deal;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    color: Colors.grey.shade100,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Icon(Icons.image_outlined, color: Colors.grey.shade400),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-${deal.discountPercent.toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (!requireLogin(context, message: 'Log in to save items to your wishlist')) return;
                      setState(() => product.isWishlisted = !product.isWishlisted);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: product.isWishlisted ? Colors.pinkAccent : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          if (deal.variantDescription.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              deal.variantDescription,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: CurrencyService.instance,
            builder: (context, _) {
              final currency = CurrencyService.instance;
              return Row(
                children: [
                  Text(
                    currency.format(product.priceValue),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currency.format(deal.discountedPrice),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}