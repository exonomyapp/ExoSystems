import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';

void main() {
  testWidgets('ExoAuthView responsive breakpoints and constraints', (WidgetTester tester) async {
    // 1. Desktop Mode (1920x1080)
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiScaleProvider.overrideWith((ref) => 1.0),
          identityProvider.overrideWith(() => IdentityControllerMock()),
        ],
        child: MaterialApp(
          theme: ConsciaTheme.darkTheme,
          home: ExoAuthView(
            onCreateIdentity: () {},
            onLinkDevice: () {},
            onToast: (msg, {bool isError = false}) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Premium Card presence
    final cardFinder = find.byKey(const Key('welcome_screen_card'));
    expect(cardFinder, findsOneWidget);
    
    final desktopWidth = tester.getSize(cardFinder).width;
    // On Desktop, width should be clamped between 440 and 600
    expect(desktopWidth, greaterThanOrEqualTo(439.0));
    expect(desktopWidth, lessThanOrEqualTo(601.0));

    // Verify "Welcome to ExoTalk" is present
    expect(find.text('Welcome to ExoTalk'), findsOneWidget);

    // 2. Mobile Mode (375x812)
    tester.view.physicalSize = const Size(375, 812);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify Card is Fluid on Mobile (should fit within 375px)
    final mobileWidth = tester.getSize(cardFinder).width;
    expect(mobileWidth, lessThanOrEqualTo(375.0));
    
    // The card should at least be able to contain the buttons (~250-300px)
    expect(mobileWidth, greaterThan(200.0));

    // Verify "ADD SOVEREIGN IDENTITY" is still accessible
    expect(find.text('ADD SOVEREIGN IDENTITY'), findsOneWidget);
  });
}

class IdentityControllerMock extends IdentityController {
  @override
  IdentityState build() {
    return IdentityState(
      knownIdentities: [],
      isLoading: false,
    );
  }

  @override
  Future<void> refreshManifest() async {}
}
