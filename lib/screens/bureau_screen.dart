import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bureau_provider.dart';
import '../models/user_model.dart';
import '../models/mandat_model.dart';
import '../models/bureau_membre_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class BureauScreen extends StatefulWidget {
  const BureauScreen({super.key});

  @override
  State<BureauScreen> createState() => _BureauScreenState();
}

class _BureauScreenState extends State<BureauScreen> {
  MandatModel? _selectedMandat;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<BureauProvider>();
    await provider.loadMandats();
    if (mounted && provider.activeMandat != null) {
      setState(() => _selectedMandat = provider.activeMandat);
      await provider.loadBureauMembres(provider.activeMandat!.id);
    } else if (mounted && provider.mandats.isNotEmpty) {
      setState(() => _selectedMandat = provider.mandats.first);
      await provider.loadBureauMembres(provider.mandats.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdminOrSysAdmin;
    final provider = context.watch<BureauProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get('bureau_title')),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: AppLocalizations.get('bureau_manage_mandats'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/manage-mandats').then((_) => _loadData());
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: provider.isLoading && provider.mandats.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.mandats.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sélecteur de mandat
                          if (provider.mandats.length > 1) ...[
                            _buildMandatSelector(provider),
                            const SizedBox(height: 16),
                          ],

                          // Info mandat
                          if (_selectedMandat != null) ...[
                            _buildMandatHeader(_selectedMandat!),
                            const SizedBox(height: 20),
                          ],

                          // Composition du bureau
                          Text(
                            AppLocalizations.get('bureau_composition'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (provider.bureauMembres.isEmpty)
                            _buildNoBureau()
                          else
                            ...provider.bureauMembres.map((m) => _buildMembreCard(m)),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 60,
            color: AppColors.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('bureau_no_mandat'),
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.get('bureau_no_mandat_desc'),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBureau() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Icon(Icons.person_off_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.get('bureau_no_members'),
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMandatSelector(BureauProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMandat?.id,
          isExpanded: true,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          items: provider.mandats.map((m) {
            return DropdownMenuItem(
              value: m.id,
              child: Row(
                children: [
                  Text(m.label, style: GoogleFonts.poppins(fontSize: 14)),
                  if (m.isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.approved.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppLocalizations.get('mandat_active'),
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.approved),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final mandat = provider.mandats.firstWhere((m) => m.id == id);
            setState(() => _selectedMandat = mandat);
            provider.loadBureauMembres(mandat.id);
          },
        ),
      ),
    );
  }

  Widget _buildMandatHeader(MandatModel mandat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1),
            const Color(0xFF1565C0).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mandat.label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (mandat.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.get('bureau_active'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                mandat.formattedPeriod,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembreCard(BureauMembreModel membre) {
    final color = _posteColor(membre.poste);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                membre.userName.isNotEmpty ? membre.userName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    membre.poste,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
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
