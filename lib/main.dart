import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const SyranoApp());
}

class SyranoApp extends StatelessWidget {
  const SyranoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시라노',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}