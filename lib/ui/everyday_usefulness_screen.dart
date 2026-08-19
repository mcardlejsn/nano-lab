import 'package:flutter/material.dart';

import 'nano_lab_section.dart';
import 'technical_lab_screen.dart';

class _EverydayTest {
  const _EverydayTest({
    required this.icon,
    required this.title,
    required this.question,
    required this.section,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String question;
  final NanoLabSection section;
  final Color accent;
}

class EverydayUsefulnessScreen extends StatelessWidget {
  const EverydayUsefulnessScreen({super.key});

  static const _tests = <_EverydayTest>[
    _EverydayTest(
      icon: Icons.spellcheck,
      title: 'Fix my writing',
      question: 'Can it correct mistakes without changing the facts?',
      section: NanoLabSection.proofreading,
      accent: Colors.green,
    ),
    _EverydayTest(
      icon: Icons.edit_note,
      title: 'Rewrite a message',
      question: 'Can it make a message sound more professional?',
      section: NanoLabSection.rewriting,
      accent: Colors.blue,
    ),
    _EverydayTest(
      icon: Icons.summarize,
      title: 'Summarize something',
      question: 'Can it shorten a long article without losing the point?',
      section: NanoLabSection.summarization,
      accent: Colors.orange,
    ),
    _EverydayTest(
      icon: Icons.sort,
      title: 'Organize information',
      question: 'Can it sort and extract details while preserving every fact?',
      section: NanoLabSection.prompt,
      accent: Colors.deepPurple,
    ),
    _EverydayTest(
      icon: Icons.image_search,
      title: 'Understand a picture',
      question: 'What does it recognize, miss, or confidently misidentify?',
      section: NanoLabSection.imageDescription,
      accent: Colors.pink,
    ),
    _EverydayTest(
      icon: Icons.mic_none,
      title: 'Transcribe speech',
      question: 'Can it preserve the meaning of an ordinary spoken note?',
      section: NanoLabSection.speechRecognition,
      accent: Colors.red,
    ),
    _EverydayTest(
      icon: Icons.offline_bolt_outlined,
      title: 'Check offline readiness',
      question: 'Are Gemini Nano and the required feature assets available?',
      section: NanoLabSection.status,
      accent: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Usefulness')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'What can Gemini Nano actually help with?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose a practical question. Nano Lab will open the matching '
              'controlled test so you can inspect the exact input, output, '
              'timing, and limitations.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 22),
            ..._tests.map(
              (test) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TechnicalLabScreen(
                            initialSection: test.section,
                            everydayMode: true,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: test.accent.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: test.accent,
                            child: Icon(test.icon),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(test.question),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: colors.outline),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Card(
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'These are controlled demonstrations, not guarantees. '
                  'Review generated results before using them, especially '
                  'when an error or omission could matter.',
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
