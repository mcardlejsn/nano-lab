import 'package:flutter/material.dart';

import 'device_report_card_screen.dart';
import 'everyday_usefulness_screen.dart';
import 'technical_lab_screen.dart';

class NanoLabHomeScreen extends StatelessWidget {
  const NanoLabHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nano Lab')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primaryContainer, colors.tertiaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_alt_outlined,
                      size: 42,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Explore Gemini Nano on your phone',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'See what on-device AI is useful for, examine the '
                      'technical details, or review the measured results.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Choose how you want to explore',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _NanoLabPathCard(
                key: const Key('everyday_usefulness_card'),
                icon: Icons.auto_awesome_outlined,
                title: 'Everyday Usefulness',
                description:
                    'Try practical tasks such as proofreading, rewriting, '
                    'summarizing, image description, and speech recognition.',
                accent: colors.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EverydayUsefulnessScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _NanoLabPathCard(
                key: const Key('technical_lab_card'),
                icon: Icons.science_outlined,
                title: 'Technical Lab',
                description:
                    'Use generation controls, inspect feature availability, '
                    'repeat fixed tests, and examine detailed timings.',
                accent: colors.tertiary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TechnicalLabScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _NanoLabPathCard(
                key: const Key('device_report_card'),
                icon: Icons.fact_check_outlined,
                title: 'Device Report Card',
                description:
                    'Read the plain-language Pixel 10 Pro results, including '
                    'strengths, limitations, speed, and offline operation.',
                accent: Colors.teal,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeviceReportCardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: colors.surfaceContainerLow,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Nano Lab uses on-device ML Kit GenAI APIs. After '
                          'required assets are installed, the tested '
                          'capabilities can run without an internet connection.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NanoLabPathCard extends StatelessWidget {
  const _NanoLabPathCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(description, style: const TextStyle(height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
