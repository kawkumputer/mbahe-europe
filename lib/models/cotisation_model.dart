enum CotisationStatus { paid, unpaid, exempted }

class CotisationModel {
  final String id;
  final String userId;
  final int month;
  final int year;
  final double amount;
  final CotisationStatus status;
  final DateTime? paidAt;

  CotisationModel({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    this.amount = 10.0,
    this.status = CotisationStatus.unpaid,
    this.paidAt,
  });

  CotisationModel copyWith({
    String? id,
    String? userId,
    int? month,
    int? year,
    double? amount,
    CotisationStatus? status,
    DateTime? paidAt,
  }) {
    return CotisationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  /// Mois cotisables : Janvier (1) à Octobre (10)
  /// Novembre (11) et Décembre (12) sont des mois de vacances
  static const List<int> cotisableMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  static const List<int> vacationMonths = [11, 12];

  static bool isCotisableMonth(int month) => cotisableMonths.contains(month);

  static const double monthlyAmount = 10.0;

  /// Total annuel : 10 mois x 10€ = 100€
  static const double yearlyTotal = 100.0;

  /// Mois des assemblées générales : Avril (4), Août (8), Décembre (12)
  static const List<int> assemblyMonths = [4, 8, 12];

  bool get isPaid => status == CotisationStatus.paid;
  bool get isExempted => status == CotisationStatus.exempted;

  String get monthName {
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return months[month];
  }

  String get statusLabel {
    switch (status) {
      case CotisationStatus.paid:
        return 'Payé';
      case CotisationStatus.unpaid:
        return 'Impayé';
      case CotisationStatus.exempted:
        return 'Exempté';
    }
  }

  String get period => '$monthName $year';
}
