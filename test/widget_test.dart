import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caca_ao_tesouro/main.dart';

void main() {
  testWidgets('Treasure Hunt smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester.pumpWidget(const CacaAoTesouroApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
