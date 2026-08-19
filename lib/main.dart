import 'package:flutter/material.dart';

import 'ui/nano_lab_home_screen.dart';

void main() {
  runApp(const NanoLabApp());
}

class NanoLabApp extends StatelessWidget {
  const NanoLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const NanoLabHomeScreen(),
    );
  }
}
