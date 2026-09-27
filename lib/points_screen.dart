import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'currency_service.dart';
import 'points_service.dart';
import 'shop_screen.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: const Text('Aura Points', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([PointsService.instance, CurrencyService.instance]),
        builder: (context, _) {
          final points = PointsService.instance;
          final currency = CurrencyService.instance;
          final progress = points.cycleProgress;
          final remaining = PointsService.pointsPerRewardCycle - points.progressInCycle;
          final milestoneCash = points.cashForPoints(PointsService.pointsPerRewardCycle);
          final sampleCash = points.cashForPoints(100);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text('Aura Points',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Earn on every order, redeem at checkout',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: 1,
                                strokeWidth: 16,
                                color: Colors.grey.shade200,
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 16,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                color: AppColors.accent,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${points.progressInCycle}',
                                  style:
                                  const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'of ${PointsService.pointsPerRewardCycle} pts',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        remaining == PointsService.pointsPerRewardCycle
                            ? 'Redeem now for a ${currency.format(milestoneCash)} Aura Cash reward'
                            : '$remaining pts to your next ${currency.format(milestoneCash)} Aura Cash reward',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${points.balance} pts available',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(
                      'Worth ${currency.format(points.redeemableCash)} off',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _infoRow(
                  title: 'Earn 1 point per ${currency.format(1)} spent',
                  subtitle: 'Points are added automatically after checkout',
                ),
                const SizedBox(height: 16),
                _infoRow(
                  title: '100 points = ${currency.format(sampleCash)}',
                  subtitle: 'Apply your points for an instant discount at checkout',
                ),
                const SizedBox(height: 16),
                _infoRow(
                  title: 'Every ${PointsService.pointsPerRewardCycle} points',
                  subtitle:
                  'Unlocks a ${currency.format(milestoneCash)} Aura Cash reward milestone',
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Text(
                      'ADD MORE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
