import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/interface/consoul.dart';

// 🧠 EDUCATIONAL CONTEXT: The ConSoul entry point.
// As an "Administrative Console," ConSoul follows the Triad Architecture
// (Spec 22), operating as a modular GUI layer that connects to the background
// Conscia daemon via a secure, local API.
//
// 💡 MENTOR TIP: Riverpod Integration
// We use 'ProviderScope' at the root of the app to enable Riverpod's 
// reactive state management. This allows any widget in the tree to 
// efficiently listen to background data (like P2P stats or mesh logs) 
// without complex prop-drilling.
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
