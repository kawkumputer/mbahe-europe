import '../models/user_model.dart';

class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  final List<UserModel> _users = [
    UserModel(
      id: '1',
      firstName: 'Admin',
      lastName: 'MBAHE',
      phone: '+33600000000',
      password: 'admin123',
      role: UserRole.admin,
      status: AccountStatus.approved,
      createdAt: DateTime(2024, 1, 1),
    ),
    UserModel(
      id: '2',
      firstName: 'Jean',
      lastName: 'Dupont',
      phone: '+33611111111',
      password: 'member123',
      role: UserRole.member,
      status: AccountStatus.approved,
      createdAt: DateTime(2024, 6, 15),
    ),
    UserModel(
      id: '3',
      firstName: 'Marie',
      lastName: 'Kamga',
      phone: '+33622222222',
      password: 'pending123',
      role: UserRole.member,
      status: AccountStatus.pending,
      createdAt: DateTime(2025, 1, 10),
    ),
  ];

  List<UserModel> get users => List.unmodifiable(_users);

  Future<UserModel?> login(String phone, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      return _users.firstWhere(
        (u) => u.phone == phone && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final exists = _users.any((u) => u.phone == phone);
    if (exists) return null;

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      password: password,
      role: UserRole.member,
      status: AccountStatus.pending,
    );

    _users.add(newUser);
    return newUser;
  }

  List<UserModel> getPendingUsers() {
    return _users
        .where((u) => u.status == AccountStatus.pending)
        .toList();
  }

  List<UserModel> getAllMembers() {
    return _users.where((u) => u.role == UserRole.member).toList();
  }

  Future<bool> approveUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;
    _users[index] = _users[index].copyWith(status: AccountStatus.approved);
    return true;
  }

  Future<bool> rejectUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return false;
    _users[index] = _users[index].copyWith(status: AccountStatus.rejected);
    return true;
  }
}
