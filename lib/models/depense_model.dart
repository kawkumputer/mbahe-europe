enum DepenseStatus { pending, approved, rejected }

class DepenseModel {
  final String id;
  final double amount;
  final String motif;
  final String? description;
  final DateTime depenseDate;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DepenseStatus status;
  final String? validatedBy;
  final String? validatedByName;
  final DateTime? validatedAt;
  final String? rejectionReason;

  DepenseModel({
    required this.id,
    required this.amount,
    required this.motif,
    this.description,
    required this.depenseDate,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.status = DepenseStatus.pending,
    this.validatedBy,
    this.validatedByName,
    this.validatedAt,
    this.rejectionReason,
  });

  factory DepenseModel.fromJson(Map<String, dynamic> json) {
    return DepenseModel(
      id: json['id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      motif: json['motif'] ?? '',
      description: json['description'],
      depenseDate: DateTime.parse(json['depense_date']),
      createdBy: json['created_by'],
      createdByName: json['created_by_name'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      status: _parseStatus(json['status']),
      validatedBy: json['validated_by'],
      validatedByName: json['validated_by_name'],
      validatedAt: json['validated_at'] != null ? DateTime.parse(json['validated_at']) : null,
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'motif': motif,
      'description': description,
      'depense_date': depenseDate.toIso8601String().split('T')[0],
      'created_by': createdBy,
      'created_by_name': createdByName,
      'status': status.name,
    };
  }

  static DepenseStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return DepenseStatus.approved;
      case 'rejected':
        return DepenseStatus.rejected;
      default:
        return DepenseStatus.pending;
    }
  }

  bool get isPending => status == DepenseStatus.pending;
  bool get isApproved => status == DepenseStatus.approved;
  bool get isRejected => status == DepenseStatus.rejected;

  String get statusLabel {
    switch (status) {
      case DepenseStatus.pending:
        return 'En attente';
      case DepenseStatus.approved:
        return 'Validée';
      case DepenseStatus.rejected:
        return 'Rejetée';
    }
  }

  String get formattedDate {
    return '${depenseDate.day.toString().padLeft(2, '0')}/${depenseDate.month.toString().padLeft(2, '0')}/${depenseDate.year}';
  }

  String get formattedAmount => '${amount.toStringAsFixed(2)}€';
}
