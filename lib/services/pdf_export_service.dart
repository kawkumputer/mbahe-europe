import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cotisation_model.dart';
import '../models/compte_rendu_model.dart';
import '../models/depense_model.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class PdfExportService {
  static const _primary = PdfColor.fromInt(0xFF6366F1);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    _regular ??= await PdfGoogleFonts.notoSansRegular();
    _bold ??= await PdfGoogleFonts.notoSansBold();
  }

  static pw.TextStyle _style({
    double fontSize = 11,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.TextStyle(
      font: bold ? _bold : _regular,
      fontBold: _bold,
      fontSize: fontSize,
      color: color,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  /// Export cotisations d'un membre pour une année
  static Future<void> exportMemberCotisations({
    required UserModel member,
    required List<CotisationModel> cotisations,
    required int year,
    required Map<String, dynamic> summary,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(AppLocalizations.get('cotisations_title')),
              pw.SizedBox(height: 20),

              // Member info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        member.fullName,
                        style: _style(fontSize: 16, bold: true),
                      ),
                      pw.Text(
                        member.phone,
                        style: _style(fontSize: 11, color: _grey),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${AppLocalizations.get('cotis_year')} $year',
                        style: _style(fontSize: 14, bold: true),
                      ),
                      pw.Text(
                        _formatDate(DateTime.now()),
                        style: _style(fontSize: 10, color: _grey),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Summary
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCell(
                      AppLocalizations.get('cotis_admin_paid'),
                      '${(summary['totalPaid'] ?? 0.0).toStringAsFixed(0)}€',
                    ),
                    _buildSummaryCell(
                      AppLocalizations.get('cotis_admin_remaining'),
                      '${(summary['remaining'] ?? 0.0).toStringAsFixed(0)}€',
                    ),
                    _buildSummaryCell(
                      AppLocalizations.get('cotis_admin_progress'),
                      '${((summary['percentage'] ?? 0.0) * 100).toInt()}%',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Table header
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _primary),
                    children: [
                      _headerCell('Mois'),
                      _headerCell('Montant'),
                      _headerCell('Statut'),
                      _headerCell('Mode'),
                      _headerCell('Date paiement'),
                    ],
                  ),
                  // Data rows
                  ...cotisations.where((c) =>
                    CotisationModel.cotisableMonths.contains(c.month)
                  ).map((c) {
                    final isVacation = CotisationModel.vacationMonths.contains(c.month);
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: c.isPaid
                          ? const PdfColor.fromInt(0xFFE8F5E9)
                          : c.isExempted
                            ? const PdfColor.fromInt(0xFFE3F2FD)
                            : PdfColors.white,
                      ),
                      children: [
                        _dataCell(months[c.month]),
                        _dataCell(isVacation ? '—' : '${c.amount.toStringAsFixed(0)}€'),
                        _dataCell(c.statusLabel),
                        _dataCell(c.paymentMethodLabel),
                        _dataCell(c.paidAt != null ? _formatDate(c.paidAt!) : '—'),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // Vacation info
              pw.Text(
                '${AppLocalizations.get('cotis_vacation_months')} \u2014 ${AppLocalizations.get('cotis_vacation_desc')}',
                style: _style(fontSize: 9, color: _grey),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'Association des ressortissants de M\'bah\u00e9 en Europe \u2014 ${_formatDate(DateTime.now())}',
                style: _style(fontSize: 8, color: _grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Cotisations_${member.fullName.replaceAll(' ', '_')}_$year',
    );
  }

  /// Export toutes les cotisations de tous les membres pour une année
  static Future<void> exportAllCotisations({
    required List<UserModel> members,
    required Map<String, List<CotisationModel>> cotisationsByUser,
    required Map<String, Map<String, dynamic>> summariesByUser,
    required int year,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];

    // Page récapitulative
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader('${AppLocalizations.get('cotisations_title')} \u2014 $year'),
              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  for (int i = 1; i <= 10; i++)
                    i: const pw.FlexColumnWidth(1),
                  11: const pw.FlexColumnWidth(1.5),
                  12: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _primary),
                    children: [
                      _headerCell('Membre'),
                      ...CotisationModel.cotisableMonths.map(
                        (m) => _headerCell(months[m].substring(0, 3)),
                      ),
                      _headerCell('Total'),
                      _headerCell('%'),
                    ],
                  ),
                  // Data
                  ...members.map((member) {
                    final cotisations = cotisationsByUser[member.id] ?? [];
                    final summary = summariesByUser[member.id] ?? {};
                    return pw.TableRow(
                      children: [
                        _dataCell(member.fullName, bold: true),
                        ...CotisationModel.cotisableMonths.map((m) {
                          final c = cotisations.where((c) => c.month == m).firstOrNull;
                          if (c == null) return _dataCell('—');
                          return pw.Container(
                            padding: const pw.EdgeInsets.all(4),
                            alignment: pw.Alignment.center,
                            color: c.isPaid
                              ? const PdfColor.fromInt(0xFFE8F5E9)
                              : c.isExempted
                                ? const PdfColor.fromInt(0xFFE3F2FD)
                                : const PdfColor.fromInt(0xFFFFEBEE),
                            child: pw.Text(
                              c.isPaid ? 'O' : c.isExempted ? 'E' : 'X',
                              style: _style(fontSize: 9, bold: true),
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }),
                        _dataCell(
                          '${(summary['totalPaid'] ?? 0.0).toStringAsFixed(0)}€',
                          bold: true,
                        ),
                        _dataCell(
                          '${((summary['percentage'] ?? 0.0) * 100).toInt()}%',
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // Legend
              pw.Row(
                children: [
                  _legendItem(const PdfColor.fromInt(0xFFE8F5E9), 'O = ${AppLocalizations.get('cotis_legend_paid')}'),
                  pw.SizedBox(width: 16),
                  _legendItem(const PdfColor.fromInt(0xFFFFEBEE), 'X = ${AppLocalizations.get('cotis_legend_unpaid')}'),
                  pw.SizedBox(width: 16),
                  _legendItem(const PdfColor.fromInt(0xFFE3F2FD), 'E ${AppLocalizations.get('cotis_legend_exempted')}'),
                ],
              ),

              pw.Spacer(),

              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'Association des ressortissants de M\'bah\u00e9 en Europe \u2014 ${_formatDate(DateTime.now())}',
                style: _style(fontSize: 8, color: _grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Cotisations_tous_les_membres_$year',
    );
  }

  /// Export un compte rendu en PDF
  static Future<void> exportCompteRendu({
    required CompteRenduModel cr,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildPdfHeader(AppLocalizations.get('cr_detail_title')),
              pw.SizedBox(height: 24),

              // Title
              pw.Text(
                cr.title,
                style: _style(fontSize: 20, bold: true),
              ),
              pw.SizedBox(height: 8),

              // Meta info
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          '${AppLocalizations.get('cr_reunion_type')}: ',
                          style: _style(fontSize: 11, bold: true),
                        ),
                        pw.Text(
                          cr.typeLabel,
                          style: _style(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text(
                          '${AppLocalizations.get('cr_reunion_date_label')}: ',
                          style: _style(fontSize: 11, bold: true),
                        ),
                        pw.Text(
                          cr.formattedDate,
                          style: _style(fontSize: 11),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Auteur: ',
                          style: _style(fontSize: 11, bold: true),
                        ),
                        pw.Text(
                          cr.authorName,
                          style: _style(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Points discutés
              pw.Text(
                AppLocalizations.get('cr_points'),
                style: _style(fontSize: 16, color: _primary, bold: true),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: _primary, thickness: 1),
              pw.SizedBox(height: 8),

              ...cr.points.asMap().entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 22,
                        height: 22,
                        decoration: const pw.BoxDecoration(
                          color: _primary,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '${entry.key + 1}',
                          style: _style(fontSize: 10, color: PdfColors.white, bold: true),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          entry.value,
                          style: _style(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Notes
              if (cr.notes != null && cr.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  AppLocalizations.get('cr_notes'),
                  style: _style(fontSize: 16, color: _primary, bold: true),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: _primary, thickness: 1),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: _lightGrey,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    cr.notes!,
                    style: _style(fontSize: 11),
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Text(
                'Association des ressortissants de M\'bah\u00e9 en Europe \u2014 ${_formatDate(DateTime.now())}',
                style: _style(fontSize: 8, color: _grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Compte_rendu_${cr.title.replaceAll(' ', '_')}_${cr.reunionDate.day}_${cr.reunionDate.month}_${cr.reunionDate.year}',
    );
  }

  /// Export liste des dépenses en PDF
  static Future<void> exportDepenses({
    required List<DepenseModel> depenses,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final approvedDepenses = depenses.where((d) => d.isApproved).toList();
    final totalApproved = approvedDepenses.fold<double>(0.0, (sum, d) => sum + d.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          children: [
            if (context.pageNumber == 1) ...[
              _buildPdfHeader(AppLocalizations.get('depenses_title')),
              pw.SizedBox(height: 20),
              // Résumé
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFEBEE),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCell(
                      AppLocalizations.get('depenses_total_approved'),
                      '${totalApproved.toStringAsFixed(2)}\u20AC',
                    ),
                    _buildSummaryCell(
                      AppLocalizations.get('depenses_validated'),
                      '${approvedDepenses.length}',
                    ),
                    _buildSummaryCell(
                      'Date',
                      _formatDate(DateTime.now()),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Association des ressortissants de M\'bah\u00e9 en Europe \u2014 ${_formatDate(DateTime.now())}',
                  style: _style(fontSize: 8, color: _grey),
                ),
                pw.Text(
                  'Page ${context.pageNumber}/${context.pagesCount}',
                  style: _style(fontSize: 8, color: _grey),
                ),
              ],
            ),
          ],
        ),
        build: (context) {
          return [
            // Table des dépenses
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _primary),
                  children: [
                    _headerCell('Date'),
                    _headerCell(AppLocalizations.get('depenses_motif')),
                    _headerCell(AppLocalizations.get('depenses_description')),
                    _headerCell(AppLocalizations.get('depenses_amount')),
                    _headerCell(AppLocalizations.get('depenses_created_by')),
                    _headerCell(AppLocalizations.get('depenses_approved_by')),
                  ],
                ),
                // Data
                ...approvedDepenses.map((d) => pw.TableRow(
                  children: [
                    _dataCell(d.formattedDate),
                    _dataCell(d.motif),
                    _dataCell(d.description ?? ''),
                    _dataCell(d.formattedAmount),
                    _dataCell(d.createdByName),
                    _dataCell(d.validatedByName ?? ''),
                  ],
                )),
                // Total row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _lightGrey),
                  children: [
                    _dataCell(''),
                    _dataCell(''),
                    _dataCell('TOTAL', bold: true),
                    _dataCell('${totalApproved.toStringAsFixed(2)}\u20AC', bold: true),
                    _dataCell(''),
                    _dataCell(''),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Depenses_validees_${DateTime.now().year}',
    );
  }

  /// Données de récap pour une réunion (pour le PDF)
  /// Export bilan des réunions en PDF
  static Future<void> exportBilanReunions({
    required List<Map<String, dynamic>> reunionSummaries,
    required double previousYearsTotal,
    required double totalAdhesion,
    required double totalDepenses,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();

    final soldeGeneral = reunionSummaries.isNotEmpty
        ? (reunionSummaries.last['cumulativeTotal'] as double)
        : previousYearsTotal + totalAdhesion - totalDepenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          children: [
            if (context.pageNumber == 1) ...[
              _buildPdfHeader(AppLocalizations.get('payment_title')),
              pw.SizedBox(height: 20),
              // Résumé général
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFBDBDBD)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCell(
                      'Solde ann\u00e9es pr\u00e9c.',
                      '${previousYearsTotal.toStringAsFixed(0)}\u20AC',
                    ),
                    _buildSummaryCell(
                      'Adh\u00e9sions',
                      '${totalAdhesion.toStringAsFixed(0)}\u20AC',
                    ),
                    _buildSummaryCell(
                      AppLocalizations.get('depenses_title'),
                      '-${totalDepenses.toStringAsFixed(0)}\u20AC',
                    ),
                    _buildSummaryCell(
                      'Solde g\u00e9n\u00e9ral',
                      '${soldeGeneral.toStringAsFixed(0)}\u20AC',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
            ],
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Association des ressortissants de M\'bah\u00e9 en Europe \u2014 ${_formatDate(DateTime.now())}',
                  style: _style(fontSize: 8, color: _grey),
                ),
                pw.Text(
                  'Page ${context.pageNumber}/${context.pagesCount}',
                  style: _style(fontSize: 8, color: _grey),
                ),
              ],
            ),
          ],
        ),
        build: (context) {
          return [
            // Table des réunions
            ...reunionSummaries.map((s) {
              final reunion = s['reunion'] as CompteRenduModel;
              final periodLabel = s['periodLabel'] as String;
              final totalPaid = (s['totalPaid'] as double);
              final totalEspece = (s['totalEspece'] as double);
              final totalVirement = (s['totalVirement'] as double);
              final totalCheque = (s['totalCheque'] as double);
              final countEspece = s['countEspece'] as int;
              final countVirement = s['countVirement'] as int;
              final countCheque = s['countCheque'] as int;
              final countTotal = s['countTotal'] as int;
              final cumulativeTotal = (s['cumulativeTotal'] as double);

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header réunion
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: const pw.BoxDecoration(
                        color: _primary,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  reunion.title,
                                  style: _style(fontSize: 13, color: PdfColors.white, bold: true),
                                ),
                                pw.Text(
                                  '${reunion.formattedDate} \u2014 $periodLabel',
                                  style: _style(fontSize: 9, color: PdfColors.white),
                                ),
                              ],
                            ),
                          ),
                          pw.Text(
                            '${totalPaid.toStringAsFixed(0)}\u20AC',
                            style: _style(fontSize: 18, color: PdfColors.white, bold: true),
                          ),
                        ],
                      ),
                    ),
                    // Détail paiements
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildPaymentDetail(AppLocalizations.get('payment_cash'), totalEspece, countEspece, const PdfColor.fromInt(0xFF2E7D32)),
                          _buildPaymentDetail(AppLocalizations.get('payment_transfer'), totalVirement, countVirement, const PdfColor.fromInt(0xFF1565C0)),
                          _buildPaymentDetail(AppLocalizations.get('payment_check'), totalCheque, countCheque, const PdfColor.fromInt(0xFF6A1B9A)),
                        ],
                      ),
                    ),
                    // Cumul
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const pw.BoxDecoration(
                        color: _lightGrey,
                        borderRadius: pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(8),
                          bottomRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${AppLocalizations.get('payment_total_cumul')} \u2014 $countTotal ${AppLocalizations.get('payment_count')}',
                            style: _style(fontSize: 10, bold: true),
                          ),
                          pw.Text(
                            '${cumulativeTotal.toStringAsFixed(0)}\u20AC',
                            style: _style(fontSize: 14, color: _primary, bold: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Bilan_reunions_${DateTime.now().year}',
    );
  }

  /// En-tête PDF partagé avec nom de l'association FR + Pulaar
  static pw.Widget _buildPdfHeader(String subtitle) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'MBAHE EUROPE',
            style: _style(fontSize: 22, color: PdfColors.white, bold: true),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Association des ressortissants de M\'bah\u00e9 en Europe',
            style: _style(fontSize: 11, color: PdfColors.white),
          ),
          pw.Text(
            'Fedde renndinde \u0253esngu Mbahe e Orop',
            style: pw.TextStyle(
              font: _regular,
              fontSize: 10,
              color: PdfColors.white,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              subtitle,
              style: _style(fontSize: 12, color: _primary, bold: true),
            ),
          ),
        ],
      ),
    );
  }

  /// Détail d'un mode de paiement pour le PDF bilan
  static pw.Widget _buildPaymentDetail(String label, double total, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          '${total.toStringAsFixed(0)}\u20AC',
          style: _style(fontSize: 14, color: color, bold: true),
        ),
        pw.Text(
          '$label ($count)',
          style: _style(fontSize: 9, color: _grey),
        ),
      ],
    );
  }

  // Helpers
  static pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: _style(fontSize: 9, color: PdfColors.white, bold: true),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _dataCell(String text, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: _style(fontSize: 9, bold: bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSummaryCell(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: _style(fontSize: 16, bold: true)),
        pw.Text(label, style: _style(fontSize: 9, color: _grey)),
      ],
    );
  }

  static pw.Widget _legendItem(PdfColor color, String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(text, style: _style(fontSize: 9)),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
