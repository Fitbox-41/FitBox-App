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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[FitBoxColors.redDark, FitBoxColors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: FitBoxColors.red.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Points balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              // Count up from 0 to the balance, matching the dashboard step ring.
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: points.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  fmt.format(value.round()),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Text('pts',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Earn by staying active · spend at checkout',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(tx.isCredit ? Icons.add : Icons.remove, color: color),
      ),
      title: Text(tx.description.isEmpty ? 'Transaction' : tx.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurface)),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.date),
          style: TextStyle(color: cs.onSurfaceVariant)),
      trailing: Text('$sign${tx.amount}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
