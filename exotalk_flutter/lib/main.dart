// =============================================================================
// main.dart — ExoTalk Application Entry Point
// =============================================================================
//
// Boot sequence:
//   1. RustLib.init()         — Loads the Rust shared library and initializes FRB
//   2. initWillowDatabase()   — Loads (or creates) the local identity vault and
//                                conversation/message stores from JSON files
//   3. initNetwork()          — Starts the Iroh QUIC endpoint, gossip overlay,
//                                and blob store for P2P mesh communication
//   4. runApp()               — Launches the Flutter widget tree wrapped in a
//                                Riverpod ProviderScope for global state management
//
// Routing: AppRouter watches the userProfileProvider and shows WelcomeScreen

// otherwise shows HomeScreen with the sidebar + chat layout.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/rust/frb_generated.dart';
import 'package:exoauth/exoauth.dart';
import 'screens/home_screen.dart';
import 'providers/toast_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

export 'package:exoauth/exoauth.dart' show uiScaleProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
  // 🧠 Educational Context: The Sovereign Boot Sequence
  // Before the Flutter UI can even paint, we must ensure the underlying 
  // sovereign engines (Willow P2P, Identity Vault, Rust FFI) are fully 
  // initialized. This ensures that the user's local identity and mesh 
  // state are the source of truth from the first frame.
  try {
    // P2P messaging is initialized lazily after profile selection
    // via initWillowDatabase(did, secret) in the identity flow.
    
    // Window management for desktop
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1100, 920),
      center: false,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAlignment(Alignment.centerRight);
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    debugPrint("Engine initialization warning: $e");
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        identityServiceProvider.overrideWithValue(RustIdentityService()),
      ],
      child: ExoTalkApp(),
    ),
  );
}

// uiScaleProvider is now provided by exoauth

final sidebarWidthProvider = StateProvider<double>((ref) => 300.0);
final sidebarVisibleProvider = StateProvider<bool>((ref) => true);

class ExoTalkApp extends ConsumerWidget {
  const ExoTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.equal, control: true): () {
          ref.read(uiScaleProvider.notifier).update((s) => (s + 0.05).clamp(0.5, 4.0));
        },
        SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): () {
          ref.read(uiScaleProvider.notifier).update((s) => (s + 0.05).clamp(0.5, 4.0));
        },
        SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          ref.read(uiScaleProvider.notifier).update((s) => (s - 0.05).clamp(0.5, 4.0));
        },
        SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): () {
          ref.read(uiScaleProvider.notifier).update((s) => (s - 0.05).clamp(0.5, 4.0));
        },
        SingleActivator(LogicalKeyboardKey.digit0, control: true): () {
          ref.read(uiScaleProvider.notifier).state = 1.0;
        },
        SingleActivator(LogicalKeyboardKey.numpad0, control: true): () {
          ref.read(uiScaleProvider.notifier).state = 1.0;
        },
      },
      child: MaterialApp(
        title: 'ExoTalk',
        debugShowCheckedModeBanner: false,
        theme: ConsciaTheme.lightTheme,
        darkTheme: ConsciaTheme.darkTheme,
        themeMode: ref.watch(themeModeProvider),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    
    // 🧠 Educational Context: Deterministic Routing
    // The AppRouter acts as the ultimate gatekeeper. If no active identity 
    // is found in the local vault (DID is null), the user is routed to 
    // the ExoAuthView. Once an identity is selected/created, the HomeScreen 
    // is swapped in with a smooth transition, locking the session to that DID.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: (identity.activeDid != null)
        ? const HomeScreen(key: ValueKey('home'))
        : ExoAuthView(
            key: const ValueKey('welcome'),
            onCreateIdentity: () => showDialog(context: context, builder: (_) => const AccountManagerModal()),
            onLinkDevice: () => showDialog(context: context, builder: (_) => const DevicePairingModal()),
            onToast: (msg, {bool isError = false}) {
              ref.read(toastProvider.notifier).show(msg, type: isError ? ToastType.error : ToastType.info);
            },
          ),
    );
  }
}
