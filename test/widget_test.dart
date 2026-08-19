import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_lab/main.dart';

void main() {
  testWidgets('Nano Lab displays the new exploration home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    expect(find.text('Nano Lab'), findsOneWidget);
    expect(find.text('Explore Gemini Nano on your phone'), findsOneWidget);
    expect(find.text('Everyday Usefulness'), findsOneWidget);
    expect(find.text('Technical Lab'), findsOneWidget);
    expect(find.text('Device Report Card'), findsOneWidget);
    expect(find.text('Memory Experiment'), findsOneWidget);
  });

  testWidgets('Memory Experiment opens without taking a measurement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    final memoryExperimentCard = find.byKey(
      const Key('memory_experiment_card'),
    );
    await tester.ensureVisible(memoryExperimentCard);
    await tester.pumpAndSettle();
    await tester.tap(memoryExperimentCard);
    await tester.pumpAndSettle();

    expect(find.text('Memory Experiment'), findsOneWidget);
    expect(find.text('Test the claim—do not assume it'), findsOneWidget);
    expect(find.text('Controlled sequence'), findsOneWidget);
  });

  testWidgets('Technical Lab preserves the existing test harness', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    final technicalLabCard = find.byKey(const Key('technical_lab_card'));
    await tester.ensureVisible(technicalLabCard);
    await tester.pumpAndSettle();
    await tester.tap(technicalLabCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Technical Lab'), findsOneWidget);
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
    expect(find.text('Dedicated speech recognition test'), findsOneWidget);
    expect(find.text('Check speech recognition status'), findsOneWidget);
    expect(find.text('Fixed phrase to speak:'), findsOneWidget);
  });

  testWidgets('Everyday Usefulness opens a simplified standalone test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NanoLabApp());

    await tester.tap(find.byKey(const Key('everyday_usefulness_card')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix my writing'));
    await tester.pumpAndSettle();

    expect(find.text('Fix My Writing'), findsWidgets);
    expect(find.text('Readiness'), findsOneWidget);
    expect(find.text('Technical Lab'), findsNothing);
  });
}
