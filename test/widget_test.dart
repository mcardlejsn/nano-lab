import 'package:flutter_test/flutter_test.dart';
import 'package:nano_lab/main.dart';

void main() {
  testWidgets('Nano Lab displays the Gemini Nano status screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    expect(find.text('Nano Lab'), findsOneWidget);
    expect(find.text('Gemini Nano status'), findsOneWidget);
    expect(find.text('NOT CHECKED'), findsWidgets);
    expect(find.text('Check Gemini Nano status'), findsOneWidget);
    expect(find.text('Dedicated summarization test'), findsOneWidget);
    expect(find.text('Check summarization status'), findsOneWidget);
    expect(find.text('Dedicated rewriting test'), findsOneWidget);
    expect(find.text('Check rewriting status'), findsOneWidget);
    expect(find.text('Dedicated proofreading test'), findsOneWidget);
    expect(find.text('Check proofreading status'), findsOneWidget);
    expect(find.text('Dedicated image description test'), findsOneWidget);
    expect(find.text('Check image description status'), findsOneWidget);
    expect(find.text('Test image'), findsOneWidget);
    expect(find.text('Synthetic house scene'), findsWidgets);
  });
}
