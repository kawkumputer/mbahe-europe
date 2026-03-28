import 'package:flutter/material.dart';

/// Couleurs spécifiques à chaque type d'association
class AssociationColors {
  // Association Générale (MBAHE Europe) - Vert
  static const Color generalPrimary = Color(0xFF1B5E20);
  static const Color generalLight = Color(0xFF4CAF50);
  static const Color generalDark = Color(0xFF0D3D11);
  static const Color generalAccent = Color(0xFF81C784);
  static const Color generalGradientStart = Color(0xFF1B5E20);
  static const Color generalGradientEnd = Color(0xFF2E7D32);

  // Association Jeunes (MBAHE Jeunes) - Orange
  static const Color jeunesPrimary = Color(0xFFE65100);
  static const Color jeunesLight = Color(0xFFFF9800);
  static const Color jeunesDark = Color(0xFFBF360C);
  static const Color jeunesAccent = Color(0xFFFFB74D);
  static const Color jeunesGradientStart = Color(0xFFE65100);
  static const Color jeunesGradientEnd = Color(0xFFF57C00);

  // Couleurs communes
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF2196F3);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  /// Obtenir la couleur primaire selon le type d'association
  static Color getPrimaryColor(String associationType) {
    return associationType == 'jeunes' ? jeunesPrimary : generalPrimary;
  }

  /// Obtenir la couleur claire selon le type d'association
  static Color getLightColor(String associationType) {
    return associationType == 'jeunes' ? jeunesLight : generalLight;
  }

  /// Obtenir la couleur sombre selon le type d'association
  static Color getDarkColor(String associationType) {
    return associationType == 'jeunes' ? jeunesDark : generalDark;
  }

  /// Obtenir la couleur d'accent selon le type d'association
  static Color getAccentColor(String associationType) {
    return associationType == 'jeunes' ? jeunesAccent : generalAccent;
  }

  /// Obtenir le début du dégradé selon le type d'association
  static Color getGradientStart(String associationType) {
    return associationType == 'jeunes' ? jeunesGradientStart : generalGradientStart;
  }

  /// Obtenir la fin du dégradé selon le type d'association
  static Color getGradientEnd(String associationType) {
    return associationType == 'jeunes' ? jeunesGradientEnd : generalGradientEnd;
  }

  /// Obtenir un dégradé linéaire selon le type d'association
  static LinearGradient getGradient(String associationType) {
    return LinearGradient(
      colors: [
        getGradientStart(associationType),
        getGradientEnd(associationType),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Obtenir le nom complet de l'association
  static String getAssociationName(String associationType) {
    return associationType == 'jeunes' ? 'MBAHE Jeunes' : 'MBAHE Europe';
  }

  /// Obtenir la description de l'association
  static String getAssociationDescription(String associationType) {
    return associationType == 'jeunes'
        ? 'Association des jeunes de M\'bahe en Europe'
        : 'Association générale des ressortissants de M\'bahe en Europe';
  }

  /// Obtenir l'icône de l'association
  static IconData getAssociationIcon(String associationType) {
    return associationType == 'jeunes' ? Icons.groups : Icons.people;
  }
}
