import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/guest_gate.dart';
import '../widgets/motion.dart';
import '../widgets/shimmer.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool guest = ref.watch(guestModeProvider);
    if (guest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: const GuestGate(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Your wallet',
          message: 'Sign in to view your points balance, earn rewards for '
              'staying active, and spend them at checkout.',
        ),
      );
    }

    final AsyncValue<WalletData> wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(walletProvider.future),
        child: wallet.when(
          loading: () => const SkeletonList(
            count: 6,
            padding: EdgeInsets.fromLTRB(16, 20, 16, 28),
          ),
          error: (Object e, _) => ListView(
            children: <Widget>[
              const SizedBox(height: 160),
              AsyncRetry(
                message: "Couldn't load your wallet.",
                onRetry: () => ref.invalidate(walletProvider),
              ),
            ],
          ),
          data: (WalletData w) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: <Widget>[
              _BalanceCard(points: w.balance),
              const SizedBox(height: 26),
              const SectionHeader('Recent activity'),
              if (w.transactions.isEmpty)
                const _EmptyLedger()
              else
                for (final WalletTransaction t in w.transactions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TxTile(t),
                  ),
            ].revealStagger(),
          ),
        ),
      ),
    );
  }
}

/// Premium fintech-style hero card: an Oswald count-up balance over the brand
/// red gradient, a soft red glow beneath, and a credit/debit legend.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[FitBoxColors.red, FitBoxColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FitBoxColors.red.withValues(alpha: 0.42),
            blurRadius: 34,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('POINTS BALANCE',
                    style: AppText.labelCaps(context,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              // Count the balance up from 0 on entry, matching the dashboard ring.
              CountUpText(
                value: points.toDouble(),
                builder: (BuildContext c, double v) => Text(
                  fmt.format(v.round()),
                  style: AppText.data(c, size: 46, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('PTS',
                    style: AppText.kinetic(context,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.9))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.18), height: 1),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const _LegendDot(color: FitBoxColors.credit, label: 'Credit'),
              const SizedBox(width: 22),
              _LegendDot(
                  color: Colors.white.withValues(alpha: 0.85), label: 'Debit'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Earn points when you’re active.\nSpend them at checkout.',
              style: AppTypography.caption(
                      size: 12, color: Colors.white.withValues(alpha: 0.8))
                  .copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

/// A tiny colored dot + label used in the balance card legend.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: AppTypography.label(
                size: 12, color: Colors.white.withValues(alpha: 0.9))),
      ],
    );
  }
}

/// A single ledger entry rendered as a clean frosted glass row: a colored
/// leading chip (credit = green, debit = red), a right-aligned Oswald amount,
/// and a caption date.
class _TxTile extends StatelessWidget {
  const _TxTile(this.tx);

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = tx.isCredit ? FitBoxColors.credit : FitBoxColors.debit;
    final String sign = tx.isCredit ? '+' : '−';
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
                tx.isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tx.description.isEmpty ? 'Transaction' : tx.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                        size: 15, color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(DateFormat('d MMM, h:mm a').format(tx.date),
                    style: AppTypography.caption(
                        size: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('$sign${tx.amount}',
              style: AppText.data(context, size: 22, color: color)),
        ],
      ),
    );
  }
}

/// A tasteful empty state shown when the ledger has no entries yet.
class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: FitBoxColors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: FitBoxColors.red, size: 30),
          ),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: AppText.kinetic(context, size: 18)),
          const SizedBox(height: 6),
          Text('Get active to start earning points.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                  size: 14, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
