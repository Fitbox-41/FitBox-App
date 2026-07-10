import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../widgets/common.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WalletData> wallet = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(walletProvider.future),
        child: wallet.when(
          loading: () => ListView(
            children: const <Widget>[
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (Object e, _) => ListView(
            children: <Widget>[
              const SizedBox(height: 180),
              AsyncRetry(
                message: "Couldn't load your wallet.",
                onRetry: () => ref.invalidate(walletProvider),
              ),
            ],
          ),
          data: (WalletData w) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              _BalanceCard(points: w.balance),
              const SizedBox(height: 24),
              const SectionHeader('Recent activity'),
              if (w.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No transactions yet. Get active to earn points!')),
                )
              else
                ...w.transactions.map((t) => _TxTile(t)),
            ],
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
          colors: <Color>[FitBoxColors.charcoal, FitBoxColors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
              Text(fmt.format(points),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
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
    final Color color = tx.isCredit ? FitBoxColors.credit : FitBoxColors.debit;
    final String sign = tx.isCredit ? '+' : '−';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(tx.isCredit ? Icons.add : Icons.remove, color: color),
      ),
      title: Text(tx.description.isEmpty ? 'Transaction' : tx.description,
          maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.date)),
      trailing: Text('$sign${tx.amount}',
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
