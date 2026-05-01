// test/onboarding_keyboard_test.dart
// Verifies that the keyboard‑first shortcuts work for the onboarding flow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:exotalk_flutter/main.dart';
import 'package:exotalk_flutter/src/rust/frb_generated.dart'; // Import Rust lib

void main() {
  testWidgets('Onboarding flow via keyboard shortcuts', (WidgetTester tester) async {
    // Initialize Rust bridge for Flutter-Rust integration.
    await RustLib.init();
    // Wrap the app in a large MediaQuery to prevent layout overflow in tests.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1080, 1920)),
        child: const ProviderScope(child: ExoTalkApp()),
      ),
    );

    // The WelcomeScreen should be visible.
    expect(find.byType(Scaffold), findsOneWidget);

    // Press Enter to open the onboarding menu (CallbackShortcuts).
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Verify that the menu items are present.
    expect(find.text('Establish fresh DID identity'), findsOneWidget);

    // Choose the first menu item – it opens AccountManagerModal.
    await tester.tap(find.text('Establish fresh DID identity'));
    await tester.pumpAndSettle();

    // The modal dialog should now be on screen.
    expect(find.byType(Dialog), findsOneWidget);

    // Use Ctrl+Enter to trigger the sync handler.
    final ctrlEnter = LogicalKeyboardKey.enter;
    // Press Control down.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(ctrlEnter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    // After sync, the modal is expected to close.
    expect(find.byType(Dialog), findsNothing);
  });
}
