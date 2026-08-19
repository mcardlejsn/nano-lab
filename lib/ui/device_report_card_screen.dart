import 'package:flutter/material.dart';

class _ReportCardEntry {
  const _ReportCardEntry({
    required this.capability,
    required this.rating,
    required this.conclusion,
    required this.color,
  });

  final String capability;
  final String rating;
  final String conclusion;
  final Color color;
}

class DeviceReportCardScreen extends StatelessWidget {
  const DeviceReportCardScreen({super.key});

  static const _entries = <_ReportCardEntry>[
    _ReportCardEntry(
      capability: 'Proofreading',
      rating: 'Strong',
      conclusion:
          'Corrected every planted error, preserved all facts, and averaged about one second.',
      color: Colors.green,
    ),
    _ReportCardEntry(
      capability: 'Rewriting',
      rating: 'Useful with review',
      conclusion:
          'Preserved the supplied facts, but added an unrequested sign-off and name placeholder.',
      color: Colors.blue,
    ),
    _ReportCardEntry(
      capability: 'Summarization',
      rating: 'Mixed',
      conclusion:
          'Fast and factually sound, but consistently omitted the article\'s central results.',
      color: Colors.orange,
    ),
    _ReportCardEntry(
      capability: 'Information organization',
      rating: 'Strong in tested task',
      conclusion:
          'Sorted five dated records correctly and preserved every fact across three runs.',
      color: Colors.green,
    ),
    _ReportCardEntry(
      capability: 'Structured extraction',
      rating: 'Useful with validation',
      conclusion:
          'Extracted the correct fields, but ignored the requested undecorated JSON format.',
      color: Colors.deepPurple,
    ),
    _ReportCardEntry(
      capability: 'Image description',
      rating: 'Mixed',
      conclusion:
          'Understood the main scenes, but omitted a prominent tree and misidentified a charging stand.',
      color: Colors.orange,
    ),
    _ReportCardEntry(
      capability: 'Speech recognition',
      rating: 'Strong with review',
      conclusion:
          'Usually preserved the complete meaning, with occasional meaningful word substitutions.',
      color: Colors.blue,
    ),
    _ReportCardEntry(
      capability: 'Offline operation',
      rating: 'Confirmed',
      conclusion:
          'All six tested capabilities completed after restarting Nano Lab fully offline.',
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Device Report Card')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Pixel 10 Pro',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gemini Nano on-device evaluation · August 2026',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall conclusion',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Useful for narrow, private, reversible assistance when '
                      'a person can review the result. Repeatability did not '
                      'guarantee correctness or completeness.',
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ..._entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.capability,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: entry.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: entry.color),
                              ),
                              child: Text(
                                entry.rating,
                                style: TextStyle(
                                  color: entry.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.conclusion,
                          style: const TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Card(
              color: colors.surfaceContainerLow,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Ratings describe the fixed tests performed on one stock '
                  'Pixel 10 Pro. They are not universal grades for every '
                  'prompt, image, speaker, device, or future model version.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
