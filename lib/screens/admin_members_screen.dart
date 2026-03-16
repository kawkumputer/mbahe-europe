import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/search_bar_widget.dart';
import '../l10n/app_localizations.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _pendingUsers = [];
  List<UserModel> _allMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final auth = context.read<AuthProvider>();
    final pending = await auth.getPendingUsers();
    final members = await auth.getAllMembers();
    if (mounted) {
      setState(() {
        _pendingUsers = pending;
        _allMembers = members;
        _isLoading = false;
      });
    }
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((u) {
      return u.firstName.toLowerCase().contains(query) ||
          u.lastName.toLowerCase().contains(query) ||
          u.fullName.toLowerCase().contains(query) ||
          u.phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingUsers = _filterUsers(_pendingUsers);
    final allMembers = _filterUsers(_allMembers);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('members_title')),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) {
                  final auth = context.watch<AuthProvider>();

                  return RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barre de recherche
                          SearchBarWidget(
                            controller: _searchController,
                            hint: AppLocalizations.get('members_search'),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),

                          const SizedBox(height: 24),

                          // Section demandes en attente
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.pending.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.pending_actions_rounded,
                                  color: AppColors.pending,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.get('members_pending'),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (pendingUsers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pending,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${pendingUsers.length}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (pendingUsers.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 40,
                                    color: AppColors.approved.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.get('members_no_pending'),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...pendingUsers.map(
                              (user) => _buildPendingUserCard(context, user, auth),
                            ),

                          const SizedBox(height: 28),

                          // Section tous les membres
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                AppLocalizations.get('members_all'),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          ...allMembers.map((user) => _buildMemberCard(user)),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPendingUserCard(
    BuildContext context,
    UserModel user,
    AuthProvider auth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.pending.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.pending.withOpacity(0.15),
                child: Text(
                  '${user.firstName[0]}${user.lastName[0]}',
                  style: GoogleFonts.poppins(
                    color: AppColors.pending,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.rejectUser(user.id);
                    await _loadUsers();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${user.fullName} ${AppLocalizations.get('members_rejected')}'),
                          backgroundColor: AppColors.rejected,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(AppLocalizations.get('members_reject')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rejected,
                    side: const BorderSide(color: AppColors.rejected),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auth.approveUser(user.id);
                    await _loadUsers();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${user.fullName} ${AppLocalizations.get('members_approved')}'),
                          backgroundColor: AppColors.approved,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(AppLocalizations.get('members_approve')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.approved,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserModel user) {
    Color statusColor;
    switch (user.status) {
      case AccountStatus.approved:
        statusColor = AppColors.approved;
        break;
      case AccountStatus.pending:
        statusColor = AppColors.pending;
        break;
      case AccountStatus.rejected:
        statusColor = AppColors.rejected;
        break;
    }

    final isUserAdmin = user.role == UserRole.admin;

    return GestureDetector(
      onTap: () => _showMemberOptions(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isUserAdmin
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isUserAdmin
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1),
              child: Text(
                '${user.firstName[0]}${user.lastName[0]}',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUserAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.get('members_role_admin'),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    user.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.statusLabel,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptions(UserModel user) {
    final isUserAdmin = user.role == UserRole.admin;
    final currentUser = context.read<AuthProvider>().currentUser;

    // Ne pas permettre de se rétrograder soi-même
    final isSelf = currentUser?.id == user.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user.phone,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.get('members_change_role')} : ${isUserAdmin ? AppLocalizations.get('members_role_admin') : AppLocalizations.get('members_role_member')}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (!isSelf)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final auth = context.read<AuthProvider>();
                      final newRole = isUserAdmin ? 'member' : 'admin';
                      final confirm = await _confirmRoleChange(user, newRole);
                      if (confirm == true) {
                        final success = await auth.updateUserRole(user.id, newRole);
                        await _loadUsers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '${user.fullName} ${AppLocalizations.get('members_role_changed')} ${newRole == 'admin' ? AppLocalizations.get('members_role_admin') : AppLocalizations.get('members_role_member')}'
                                    : AppLocalizations.get('error'),
                              ),
                              backgroundColor: success ? AppColors.approved : AppColors.rejected,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      isUserAdmin ? Icons.person_rounded : Icons.admin_panel_settings_rounded,
                      size: 20,
                    ),
                    label: Text(
                      isUserAdmin ? AppLocalizations.get('members_demote') : AppLocalizations.get('members_promote'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUserAdmin ? AppColors.pending : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                )
              else
                Text(
                  AppLocalizations.get('members_cannot_change_self'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmRoleChange(UserModel user, String newRole) {
    final action = newRole == 'admin' ? AppLocalizations.get('members_promote') : AppLocalizations.get('members_demote');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.get('members_confirm_change'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        content: Text(
          '$action ${user.fullName} ?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.get('cancel'), style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == 'admin' ? AppColors.primary : AppColors.pending,
            ),
            child: Text(
              AppLocalizations.get('confirm'),
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
