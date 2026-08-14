import 'package:flutter_test/flutter_test.dart';
import 'package:nano_lab/main.dart';

void main() {
  testWidgets('Nano Lab displays the Gemini Nano status screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    expect(find.text('Nano Lab'), findsOneWidget);
    expect(find.text('Gemini Nano status'), findsOneWidget);
    expect(find.text('NOT CHECKED'), findsOneWidget);
    expect(find.text('Check Gemini Nano status'), findsOneWidget);
  });
}
