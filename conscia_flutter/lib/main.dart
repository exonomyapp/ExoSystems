import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/interface/consoul.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ConSoulApp(),
    ),
  );
}

class ConSoulApp extends ConsumerWidget {
  const ConSoulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'ConSoul',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117), // GitHub Dark bg
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF238636), // Conscia accent green
          surface: Color(0xFF161B22),
        ),
      ),
      home: const ConSoul(),
      debugShowCheckedModeBanner: false,
    );
  }
}
