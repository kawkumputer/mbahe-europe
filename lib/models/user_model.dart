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
  final DateTime? dateOfBirth;
  final bool adhesionPaid;
  final DateTime? adhesionPaidAt;
  final double adhesionAmount;
  final List<String> associationTypes;
  final Map<String, UserRole> associationRoles;

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
    this.dateOfBirth,
    this.adhesionPaid = false,
    this.adhesionPaidAt,
    this.adhesionAmount = 10.0,
    this.associationTypes = const ['general'],
    Map<String, UserRole>? associationRoles,
  }) : createdAt = createdAt ?? DateTime.now(),
       associationRoles = associationRoles ?? {'general': UserRole.member};

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
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      adhesionPaid: json['adhesion_paid'] ?? false,
      adhesionPaidAt: json['adhesion_paid_at'] != null
          ? DateTime.parse(json['adhesion_paid_at'])
          : null,
      adhesionAmount: (json['adhesion_amount'] ?? 10.0).toDouble(),
      associationTypes: (json['association_types'] as List<dynamic>?)?.cast<String>() ?? ['general'],
      associationRoles: _parseAssociationRoles(json['association_roles']),
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
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'association_types': associationTypes,
      'association_roles': _associationRolesToJson(associationRoles),
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

  static Map<String, UserRole> _parseAssociationRoles(dynamic rolesJson) {
    print('DEBUG _parseAssociationRoles: rolesJson = $rolesJson (type: ${rolesJson.runtimeType})');
    if (rolesJson == null) return {'general': UserRole.member};
    
    final Map<String, UserRole> roles = {};
    if (rolesJson is Map) {
      rolesJson.forEach((key, value) {
        print('DEBUG _parseAssociationRoles: key=$key, value=$value');
        roles[key.toString()] = _parseRole(value.toString());
      });
    }
    print('DEBUG _parseAssociationRoles: result = $roles');
    
    return roles.isEmpty ? {'general': UserRole.member} : roles;
  }

  static Map<String, String> _associationRolesToJson(Map<String, UserRole> roles) {
    final Map<String, String> result = {};
    roles.forEach((key, value) {
      result[key] = _roleToString(value);
    });
    return result;
  }

  /// Obtenir le rôle pour une association spécifique
  UserRole getRoleForAssociation(String associationType) {
    return associationRoles[associationType] ?? UserRole.member;
  }

  /// Vérifier si l'utilisateur est admin pour une association donnée
  bool isAdminForAssociation(String associationType) {
    final role = getRoleForAssociation(associationType);
    return role == UserRole.admin || role == UserRole.sysAdmin;
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
    DateTime? dateOfBirth,
    bool? adhesionPaid,
    DateTime? adhesionPaidAt,
    double? adhesionAmount,
    List<String>? associationTypes,
    Map<String, UserRole>? associationRoles,
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
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      adhesionPaid: adhesionPaid ?? this.adhesionPaid,
      adhesionPaidAt: adhesionPaidAt ?? this.adhesionPaidAt,
      adhesionAmount: adhesionAmount ?? this.adhesionAmount,
      associationTypes: associationTypes ?? this.associationTypes,
      associationRoles: associationRoles ?? this.associationRoles,
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
