import 'package:flutter/material.dart';

void main() {
  runApp(const ConsciaCMC());
}

class ConsciaCMC extends StatelessWidget {
  const ConsciaCMC({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conscia Management Console',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const Scaffold(
        body: Center(
          child: Text("Conscia Management Console (CMC)\n[Governance System Pending]"),
        ),
      ),
    );
  }
}
