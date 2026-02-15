import 'package:flutter_test/flutter_test.dart';

import 'package:mbahe_europe/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MbaheEuropeApp());
    await tester.pump();
    expect(find.text('MBAHE'), findsOneWidget);
  });
}
