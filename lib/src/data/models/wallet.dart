/// The user's current points balance in the shared FitBox wallet.
class WalletBalance {
  const WalletBalance({required this.points});

  final int points;
}

enum WalletTxType { credit, debit }

/// A single entry in the wallet ledger.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  final String id;
  final WalletTxType type;
  final int amount;
  final String description;
  final DateTime date;

  bool get isCredit => type == WalletTxType.credit;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type']?.toString() == 'debit')
          ? WalletTxType.debit
          : WalletTxType.credit,
      amount: (json['amount'] as num?)?.round() ?? 0,
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Wallet balance + recent transactions, as returned by `GET /api/wallet`.
class WalletData {
  const WalletData({required this.balance, required this.transactions});

  final int balance;
  final List<WalletTransaction> transactions;

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List?) ?? const [];
    return WalletData(
      balance: (json['balance'] as num?)?.round() ?? 0,
      transactions: list
          .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
