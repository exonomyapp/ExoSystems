// This is a basic smoke test for the ExoTalk application.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exotalk_flutter/main.dart';

import 'package:exotalk_flutter/src/rust/frb_generated.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await RustLib.init();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ExoTalkApp()));

    // Verify that the WelcomeScreen is shown.
    expect(find.text('Welcome to ExoTalk'), findsOneWidget);
  });
}
