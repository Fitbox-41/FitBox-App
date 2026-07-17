import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WalletData> wallet = ref.watch(walletProvider);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(walletProvider.future),
        child: wallet.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              _BalanceCard(points: w.balance),
              const SizedBox(height: 24),
              const SectionHeader('Recent activity'),
              if (w.transactions.isEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Text(
                        'No transactions yet.\nGet active to earn points!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                )
              else
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: <Widget>[
                      for (final t in w.transactions) _TxTile(t),
                    ],
                  ),
                ),
            ]
                .animate(interval: 70.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
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
              color: FitBoxColors.red.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: -4,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: <Widget>[
          Text('AVAILABLE BALANCE',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              // Count up from 0 to the balance, matching the dashboard ring.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: points.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  fmt.format(value.round()),
                  style: AppText.data(context,
                      size: 46, color: Colors.white, italic: true),
                ),
              ),
              const SizedBox(width: 8),
              Text('PTS',
                  style: AppText.kinetic(context,
                      size: 20, color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Earn by staying active · spend at checkout',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(this.tx);

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = tx.isCredit ? FitBoxColors.credit : FitBoxColors.debit;
    final String sign = tx.isCredit ? '+' : '−';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(tx.isCredit ? Icons.trending_up : Icons.trending_down,
            color: color, size: 22),
      ),
      title: Text(tx.description.isEmpty ? 'Transaction' : tx.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.date),
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      trailing: Text('$sign${tx.amount}',
          style: AppText.data(context, size: 20, color: color, italic: true)),
    );
  }
}
