import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/supabase_document_service.dart';
import '../theme/app_theme.dart';

class StatutsScreen extends StatefulWidget {
  const StatutsScreen({super.key});

  @override
  State<StatutsScreen> createState() => _StatutsScreenState();
}

class _StatutsScreenState extends State<StatutsScreen> {
  final _service = SupabaseDocumentService();
  List<Map<String, String>> _articles = [];
  String? _updatedByName;
  DateTime? _updatedAt;
  bool _isLoading = true;

  static final List<Map<String, String>> _defaultArticles = [
    {'title': 'Article 1 — Dénomination', 'content': 'Il est fondé entre les adhérents aux présents statuts une association régie par la loi du 1er juillet 1901, ayant pour dénomination : MBAHE EUROPE.'},
    {'title': 'Article 2 — Objet', 'content': 'L\'association a pour objet :\n• Regrouper les ressortissants de MBAHE vivant en Europe\n• Renforcer les liens de solidarité entre les membres\n• Contribuer au développement socio-économique du village de MBAHE\n• Organiser des activités culturelles, sociales et éducatives\n• Promouvoir l\'entraide et la cohésion communautaire'},
    {'title': 'Article 3 — Siège social', 'content': 'Le siège social est fixé en Europe. Il pourra être transféré par simple décision du bureau.'},
    {'title': 'Article 4 — Durée', 'content': 'La durée de l\'association est illimitée.'},
    {'title': 'Article 5 — Composition', 'content': 'L\'association se compose de :\n• Membres actifs : toute personne originaire de MBAHE ou ayant un lien avec le village, résidant en Europe, à jour de ses cotisations\n• Membres d\'honneur : personnes ayant rendu des services éminents à l\'association'},
    {'title': 'Article 6 — Admission', 'content': 'Pour faire partie de l\'association, il faut :\n• Remplir une demande d\'adhésion via l\'application\n• Être approuvé par le bureau de l\'association\n• S\'acquitter de la cotisation annuelle'},
    {'title': 'Article 7 — Cotisations', 'content': 'Les membres s\'acquittent d\'une cotisation mensuelle dont le montant est fixé par l\'assemblée générale. Les cotisations sont dues de Janvier à Octobre. Les mois de Novembre et Décembre sont des mois de vacances.'},
    {'title': 'Article 8 — Perte de qualité de membre', 'content': 'La qualité de membre se perd par :\n• La démission adressée par écrit au bureau\n• Le non-paiement des cotisations après mise en demeure\n• L\'exclusion prononcée par le bureau pour motif grave'},
    {'title': 'Article 9 — Administration', 'content': 'L\'association est dirigée par un bureau composé de :\n• Un(e) Président(e)\n• Un(e) Vice-Président(e)\n• Un(e) Secrétaire Général(e)\n• Un(e) Trésorier(ère)\n• Des membres du bureau\n\nLe bureau est élu par l\'assemblée générale pour un mandat défini par le règlement intérieur.'},
    {'title': 'Article 10 — Assemblée générale', 'content': 'L\'assemblée générale comprend tous les membres actifs de l\'association. Elle se réunit au moins une fois par an sur convocation du bureau. Les décisions sont prises à la majorité des membres présents.'},
    {'title': 'Article 11 — Ressources', 'content': 'Les ressources de l\'association comprennent :\n• Les cotisations des membres\n• Les dons et subventions\n• Les recettes des activités organisées\n• Toute autre ressource autorisée par la loi'},
    {'title': 'Article 12 — Modification des statuts', 'content': 'Les statuts peuvent être modifiés par l\'assemblée générale extraordinaire, sur proposition du bureau ou d\'au moins un tiers des membres actifs.'},
    {'title': 'Article 13 — Dissolution', 'content': 'La dissolution de l\'association ne peut être prononcée que par l\'assemblée générale extraordinaire. En cas de dissolution, l\'actif net sera attribué à une association ayant des buts similaires.'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    final doc = await _service.getDocument('statuts');
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
    final success = await _service.updateDocument('statuts', jsonStr);
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
        title: const Text('Statuts'),
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
          const Icon(Icons.gavel_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            'STATUTS DE L\'ASSOCIATION',
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
