enum UserRole { admin, member, sysAdmin }

enum AccountStatus { pending, approved, rejected }

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String username;
  final String? password;
  final UserRole role;
  final AccountStatus status;
  final DateTime createdAt;
  final String? photoUrl;
  final String? bio;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.username,
    this.password,
    this.role = UserRole.member,
    this.status = AccountStatus.pending,
    DateTime? createdAt,
    this.photoUrl,
    this.bio,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      photoUrl: json['photo_url'],
      bio: json['bio'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'username': username,
      'role': _roleToString(role),
      'status': _statusToString(status),
      'photo_url': photoUrl,
      'bio': bio,
    };
  }

  static String _statusToString(AccountStatus status) {
    switch (status) {
      case AccountStatus.approved:
        return 'approved';
      case AccountStatus.rejected:
        return 'rejected';
      case AccountStatus.pending:
        return 'pending';
    }
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

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'sys_admin':
        return UserRole.sysAdmin;
      default:
        return UserRole.member;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.sysAdmin:
        return 'sys_admin';
      case UserRole.member:
        return 'member';
    }
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? username,
    String? password,
    UserRole? role,
    AccountStatus? status,
    DateTime? createdAt,
    String? photoUrl,
    String? bio,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      updatedAt: updatedAt ?? this.updatedAt,
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
