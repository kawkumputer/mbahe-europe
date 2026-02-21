enum UserRole { admin, member }

enum AccountStatus { pending, approved, rejected }

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? password;
  final UserRole role;
  final AccountStatus status;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.password,
    this.role = UserRole.member,
    this.status = AccountStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.member,
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role == UserRole.admin ? 'admin' : 'member',
      'status': status.name,
    };
  }

  static AccountStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      default:
        return AccountStatus.pending;
    }
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? password,
    UserRole? role,
    AccountStatus? status,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullName => '$firstName $lastName';

  String get statusLabel {
    switch (status) {
      case AccountStatus.pending:
        return 'En attente';
      case AccountStatus.approved:
        return 'Approuvé';
      case AccountStatus.rejected:
        return 'Rejeté';
    }
  }
}
