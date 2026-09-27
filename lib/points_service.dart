import 'package:flutter/foundation.dart';

/// Aura Points — a simple loyalty ledger.
///
/// Earning: 1 Aura Point per \$1 actually paid at checkout.
/// Redeeming: 100 points = \$2 off (50 points = \$1), applied as a
/// discount at checkout.
/// Rewards: every 500 points unlocks a cash reward milestone (matches the
/// redemption rate above — it's just a friendly milestone to show progress
/// toward on the Points screen).
///
/// This is mock/in-memory state for the prototype. Replace with a real
/// backend-synced balance once one exists — everything else in the app only
/// ever reads `balance`/`redeemableCash` and calls `addPoints`/`redeem`, so
/// the swap stays contained to this file.
class PointsService extends ChangeNotifier {
  PointsService._internal();
  static final PointsService instance = PointsService._internal();

  static const int pointsPerRewardCycle = 500;
  static const int pointsPerDollarEarned = 1;
  static const int pointsPerDollarRedeemed = 50; // 100 points = $2

  int _balance = 340; // seeded so the screen has something to show
  int get balance => _balance;

  /// Progress within the current 500-point reward cycle (0..499).
  int get progressInCycle => _balance % pointsPerRewardCycle;

  /// How much of a reward cycle is complete, as a 0..1 fraction.
  double get cycleProgress => progressInCycle / pointsPerRewardCycle;

  /// Dollar value of the full current balance if redeemed right now.
  double get redeemableCash => cashForPoints(_balance);

  int pointsForCash(double cash) =>
      (cash * pointsPerDollarRedeemed).round().clamp(0, 1 << 30);

  double cashForPoints(int points) => points / pointsPerDollarRedeemed;

  /// Points earned for an order where [amountPaid] was the cash total.
  int earnedFor(double amountPaid) =>
      (amountPaid * pointsPerDollarEarned).round().clamp(0, 1 << 30);

  void addPoints(int points) {
    if (points <= 0) return;
    _balance += points;
    notifyListeners();
  }

  /// Attempts to spend [points]. Returns false (and changes nothing) if the
  /// balance is insufficient.
  bool redeem(int points) {
    if (points <= 0 || points > _balance) return false;
    _balance -= points;
    notifyListeners();
    return true;
  }
}
