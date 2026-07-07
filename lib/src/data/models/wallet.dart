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
}
