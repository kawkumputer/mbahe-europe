/// Helper pour générer le pied de page des PDF en fonction de l'association
String getPdfFooterText(String associationType) {
  final date = _formatDate(DateTime.now());
  if (associationType == 'jeunes') {
    return 'La Jeunesse de M\'bahé en France — $date';
  }
  return 'Association des ressortissants de M\'bahé en Europe — $date';
}

String _formatDate(DateTime date) {
  final months = [
    '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}
