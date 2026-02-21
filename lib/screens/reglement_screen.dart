import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/supabase_document_service.dart';
import '../theme/app_theme.dart';

class ReglementScreen extends StatefulWidget {
  const ReglementScreen({super.key});

  @override
  State<ReglementScreen> createState() => _ReglementScreenState();
}

class _ReglementScreenState extends State<ReglementScreen> {
  final _service = SupabaseDocumentService();
  List<Map<String, String>> _articles = [];
  String? _updatedByName;
  DateTime? _updatedAt;
  bool _isLoading = true;

  static final List<Map<String, String>> _defaultArticles = [
    {'title': 'Article 1 — Objet', 'content': 'Le présent règlement intérieur complète et précise les statuts de l\'association MBAHE EUROPE. Il s\'applique à tous les membres sans exception.'},
    {'title': 'Article 2 — Adhésion', 'content': 'Toute personne souhaitant adhérer à l\'association doit :\n• Créer un compte via l\'application officielle\n• Fournir ses nom, prénom et numéro de téléphone\n• Attendre la validation de son compte par le bureau\n• S\'acquitter de sa première cotisation dans le mois suivant l\'approbation'},
    {'title': 'Article 3 — Montant et périodicité', 'content': 'Le montant de la cotisation mensuelle est fixé par l\'assemblée générale. Les cotisations sont dues chaque mois de Janvier à Octobre. Les mois de Novembre et Décembre sont des mois de vacances.'},
    {'title': 'Article 4 — Modes de paiement', 'content': 'Les cotisations peuvent être réglées par :\n• Espèces\n• Chèque\n• Virement bancaire\n• Tout autre moyen validé par le bureau'},
    {'title': 'Article 5 — Retard de paiement', 'content': 'Tout membre en retard de paiement de plus de 3 mois sera relancé par le bureau. En cas de non-régularisation après mise en demeure, le bureau pourra prononcer la suspension du membre.'},
    {'title': 'Article 6 — Exemptions', 'content': 'Un membre en situation de chômage ou de difficulté financière avérée peut demander une exemption temporaire de cotisation. Cette exemption est accordée par le bureau au cas par cas.'},
    {'title': 'Article 7 — Droits des membres', 'content': 'Tout membre actif à jour de ses cotisations a le droit de :\n• Participer aux assemblées générales avec voix délibérative\n• Être éligible aux fonctions du bureau\n• Accéder aux comptes rendus des réunions\n• Bénéficier de l\'entraide et de la solidarité de l\'association\n• Consulter les informations de l\'association via l\'application'},
    {'title': 'Article 8 — Devoirs des membres', 'content': 'Tout membre s\'engage à :\n• Respecter les statuts et le présent règlement intérieur\n• S\'acquitter régulièrement de ses cotisations\n• Participer activement à la vie de l\'association\n• Faire preuve de respect envers les autres membres\n• Préserver l\'image et la réputation de l\'association'},
    {'title': 'Article 9 — Réunions ordinaires', 'content': 'Les réunions ordinaires sont convoquées par le bureau. L\'ordre du jour est communiqué à l\'avance. Un compte rendu est rédigé après chaque réunion et mis à disposition des membres via l\'application.'},
    {'title': 'Article 10 — Présence', 'content': 'La participation aux réunions est vivement encouragée. En cas d\'absence, le membre peut se faire représenter par un autre membre muni d\'une procuration.'},
    {'title': 'Article 11 — Sanctions disciplinaires', 'content': 'En cas de manquement aux obligations, le bureau peut prononcer :\n• Un avertissement verbal ou écrit\n• Une suspension temporaire\n• Une exclusion définitive (après audition du membre concerné)'},
    {'title': 'Article 12 — Procédure', 'content': 'Toute sanction est précédée d\'une audition du membre concerné qui peut présenter sa défense. La décision est prise à la majorité des membres du bureau.'},
    {'title': 'Article 13 — Modification', 'content': 'Le présent règlement intérieur peut être modifié par le bureau après consultation de l\'assemblée générale.'},
    {'title': 'Article 14 — Entrée en vigueur', 'content': 'Le présent règlement intérieur entre en vigueur à compter de son adoption par l\'assemblée générale.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _service.getDocument('reglement');
    if (mounted) {
      setState(() {
        _articles = _parseArticles(doc?['content'] as String?);
        _updatedByName = doc?['updated_by_name'] as String?;
        _updatedAt = doc?['updated_at'] != null ? DateTime.tryParse(doc!['updated_at']) : null;
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _parseArticles(String? content) {
    if (content == null || content.isEmpty) return List.from(_defaultArticles);
    try {
      final list = jsonDecode(content) as List;
      return list.map<Map<String, String>>((e) => {
        'title': (e['title'] ?? '') as String,
        'content': (e['content'] ?? '') as String,
      }).toList();
    } catch (_) {
      return List.from(_defaultArticles);
    }
  }

  Future<void> _saveArticles() async {
    final jsonStr = jsonEncode(_articles);
    final success = await _service.updateDocument('reglement', jsonStr);
    if (success && mounted) {
      _loadDocument();
    }
  }

  void _addArticle() {
    _showArticleDialog(
      dialogTitle: 'Ajouter un article',
      onSave: (title, content) {
        setState(() => _articles.add({'title': title, 'content': content}));
        _saveArticles();
      },
    );
  }

  void _editArticle(int index) {
    _showArticleDialog(
      dialogTitle: 'Modifier l\'article',
      initialTitle: _articles[index]['title']!,
      initialContent: _articles[index]['content']!,
      onSave: (title, content) {
        setState(() => _articles[index] = {'title': title, 'content': content});
        _saveArticles();
      },
    );
  }

  void _deleteArticle(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${_articles[index]['title']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _articles.removeAt(index));
              _saveArticles();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showArticleDialog({
    required String dialogTitle,
    String initialTitle = '',
    String initialContent = '',
    required void Function(String title, String content) onSave,
  }) {
    final titleCtrl = TextEditingController(text: initialTitle);
    final contentCtrl = TextEditingController(text: initialContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 8,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Contenu',
                  labelStyle: GoogleFonts.poppins(fontSize: 13),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                onSave(titleCtrl.text.trim(), contentCtrl.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Règlement intérieur'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _addArticle,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (_updatedByName != null && _updatedAt != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Mis à jour par $_updatedByName le ${_updatedAt!.day}/${_updatedAt!.month}/${_updatedAt!.year}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_articles.isEmpty)
                      Center(
                        child: Text(
                          'Aucun article pour le moment',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ..._articles.asMap().entries.map((entry) =>
                        _buildArticleCard(entry.key, entry.value, isAdmin)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildArticleCard(int index, Map<String, String> article, bool isAdmin) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  article['title'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (isAdmin) ...[
                InkWell(
                  onTap: () => _editArticle(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _deleteArticle(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            article['content'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            'RÈGLEMENT INTÉRIEUR',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'MBAHE EUROPE',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
