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
    final AsyncValue<WalletBalance> balance = ref.watch(walletBalanceProvider);
    final AsyncValue<List<WalletTransaction>> txns =
        ref.watch(walletTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletBalanceProvider);
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _BalanceCard(balance: balance, ref: ref),
            const SizedBox(height: 24),
            const SectionHeader('Recent activity'),
            _TransactionList(txns: txns, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.ref});

  final AsyncValue<WalletBalance> balance;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final NumberFormat fmt = NumberFormat.decimalPattern();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[FitBoxColors.green, FitBoxColors.greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Points balance',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          balance.when(
            loading: () => const SizedBox(
              height: 40,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
            error: (Object e, _) => TextButton(
              onPressed: () => ref.invalidate(walletBalanceProvider),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
            data: (WalletBalance b) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(fmt.format(b.points),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                const Text('pts',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('Earn by staying active · spend at checkout',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.txns, required this.ref});

  final AsyncValue<List<WalletTransaction>> txns;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return txns.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, _) => AsyncRetry(
        message: "Couldn't load transactions.",
        onRetry: () => ref.invalidate(walletTransactionsProvider),
      ),
      data: (List<WalletTransaction> list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No transactions yet.')),
          );
        }
        return Column(
          children: list.map((WalletTransaction t) => _TxTile(t)).toList(),
        );
      },
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
      title: Text(tx.description, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormat('d MMM, h:mm a').format(tx.date)),
      trailing: Text('$sign${tx.amount}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
