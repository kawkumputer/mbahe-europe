import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bureau_provider.dart';
import '../models/mandat_model.dart';
import '../models/bureau_membre_model.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class ManageBureauScreen extends StatefulWidget {
  const ManageBureauScreen({super.key});

  @override
  State<ManageBureauScreen> createState() => _ManageBureauScreenState();
}

class _ManageBureauScreenState extends State<ManageBureauScreen> {
  late MandatModel _mandat;
  bool _initialized = false;
  List<UserModel> _allMembers = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _mandat = ModalRoute.of(context)!.settings.arguments as MandatModel;
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<BureauProvider>();
    final auth = context.read<AuthProvider>();
    await provider.loadBureauMembres(_mandat.id);
    _allMembers = await auth.getAllMembers();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BureauProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_mandat.label),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMembreDialog(provider),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: provider.isLoading && provider.bureauMembres.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: provider.bureauMembres.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.person_add_rounded, size: 60, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                const SizedBox(height: 16),
                                Text(AppLocalizations.get('bureau_no_bureau_members'), style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(AppLocalizations.get('bureau_add_hint'), style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.bureauMembres.length,
                        itemBuilder: (context, index) {
                          return _buildMembreCard(provider.bureauMembres[index], provider);
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildMembreCard(BureauMembreModel membre, BureauProvider provider) {
    final color = _posteColor(membre.poste);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                membre.userName.isNotEmpty ? membre.userName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  membre.userName,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    membre.poste,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditMembreDialog(membre, provider);
              } else if (value == 'delete') {
                _confirmRemoveMembre(membre, provider);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Text(AppLocalizations.get('edit'))),
              PopupMenuItem(value: 'delete', child: Text(AppLocalizations.get('bureau_remove_member'), style: const TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMembreDialog(BureauProvider provider) {
    String? selectedUserId;
    String? selectedPoste;
    final occupiedPostes = provider.bureauMembres.map((m) => m.poste).toSet();
    final availablePostes = BureauMembreModel.postes.where((p) => !occupiedPostes.contains(p)).toList();

    if (availablePostes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('bureau_all_posts_taken')), backgroundColor: AppColors.pending),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.get('bureau_add_member'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du poste
                DropdownButtonFormField<String>(
                  initialValue: selectedPoste,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('bureau_post'),
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  items: availablePostes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPoste = v),
                ),
                const SizedBox(height: 14),
                // Sélection du membre
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('bureau_member'),
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  isExpanded: true,
                  items: _allMembers.map((u) => DropdownMenuItem(
                    value: u.id,
                    child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.get('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId == null || selectedPoste == null) return;
                Navigator.pop(ctx);
                final user = _allMembers.firstWhere((u) => u.id == selectedUserId);
                final success = await provider.addBureauMembre(
                  mandatId: _mandat.id,
                  userId: user.id,
                  userName: user.fullName,
                  poste: selectedPoste!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '${user.fullName} ${AppLocalizations.get('bureau_added')} $selectedPoste' : AppLocalizations.get('error')),
                      backgroundColor: success ? AppColors.approved : AppColors.rejected,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(AppLocalizations.get('add'), style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMembreDialog(BureauMembreModel membre, BureauProvider provider) {
    String? selectedUserId = membre.userId;
    String? selectedPoste = membre.poste;
    final occupiedPostes = provider.bureauMembres
        .where((m) => m.id != membre.id)
        .map((m) => m.poste)
        .toSet();
    final availablePostes = BureauMembreModel.postes.where((p) => !occupiedPostes.contains(p)).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.get('edit'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPoste,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('bureau_post'),
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  items: availablePostes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => selectedPoste = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get('bureau_member'),
                    labelStyle: GoogleFonts.poppins(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  isExpanded: true,
                  items: _allMembers.map((u) => DropdownMenuItem(
                    value: u.id,
                    child: Text(u.fullName, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedUserId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.get('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (selectedUserId == null || selectedPoste == null) return;
                Navigator.pop(ctx);
                final user = _allMembers.firstWhere((u) => u.id == selectedUserId);
                final success = await provider.updateBureauMembre(
                  membre.id,
                  mandatId: _mandat.id,
                  userId: user.id,
                  userName: user.fullName,
                  poste: selectedPoste!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? AppLocalizations.get('bureau_member_updated') : AppLocalizations.get('error')),
                      backgroundColor: success ? AppColors.approved : AppColors.rejected,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(AppLocalizations.get('save'), style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMembre(BureauMembreModel membre, BureauProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.get('bureau_remove_member'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text('${AppLocalizations.get('bureau_remove_confirm')} ${membre.userName} ${AppLocalizations.get('bureau_remove_confirm_desc')} ${membre.poste} ?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.get('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.removeBureauMembre(membre.id, _mandat.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? AppLocalizations.get('bureau_member_removed') : AppLocalizations.get('error')),
                    backgroundColor: success ? AppColors.approved : AppColors.rejected,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.get('bureau_remove_member'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _posteColor(String poste) {
    if (poste.contains('Président')) return const Color(0xFF0D47A1);
    if (poste.contains('Secrétaire')) return const Color(0xFF6A1B9A);
    if (poste.contains('Trésorier')) return const Color(0xFF2E7D32);
    if (poste.contains('Commissaire')) return const Color(0xFFEF6C00);
    if (poste.contains('communication')) return const Color(0xFFD32F2F);
    return const Color(0xFF455A64);
  }
}
