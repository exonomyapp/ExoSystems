// =============================================================================
// exo_auth_view.dart — Auth View (Spec 17)
// =============================================================================
// This component is the primary entry point for ExoTalk.
// It follows Spec 17's "Fixed Frame" protocol, ensuring that 
// identity components and onboarding elements maintain structural 
// stability across all desktop and mobile viewports.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

import '../theme.dart';
import '../providers.dart';
import '../models.dart';
import '../services/oauth_service.dart';


class ExoAuthView extends ConsumerStatefulWidget {
  final VoidCallback onCreateIdentity;
  final VoidCallback onLinkDevice;
  final void Function(String message, {bool isError}) onToast;

  const ExoAuthView({
    super.key,
    required this.onCreateIdentity,
    required this.onLinkDevice,
    required this.onToast,
  });

  @override
  ConsumerState<ExoAuthView> createState() => _ExoAuthViewState();
}

class _ExoAuthViewState extends ConsumerState<ExoAuthView> {
  final MenuController _menuController = MenuController();

  // EDUCATIONAL CONTEXT: OAuth Integration
  // This function facilitates the transition from OAuth providers 
  // (Google/GitHub) to identities (did:peer). 
  // It checks if a linked local persona already exists; if not, it triggers 
  // the creation of a new, local-only vault that is permanently associated 
  // with the cryptographic hash of the OAuth 'sub' field.
  Future<void> _linkAndLogin(OAuthProviderConfig config) async {
    try {
      final result = await OAuthService.authenticate(config);
      
      final service = ref.read(identityServiceProvider);
      final existingDid = await service.findDidForOauth(provider: config.id, sub: result.sub);
      
      if (existingDid != null) {
        await ref.read(identityProvider.notifier).switchIdentity(existingDid);
      } else {
        if (mounted) {
          await _showLinkIdentityDialog(config, result);
        }
      }
    } catch (e) {
      if (mounted) widget.onToast("Sign-in failed: $e", isError: true);
    }
  }

  Future<void> _showLinkIdentityDialog(OAuthProviderConfig config, ({String sub, String displayName, String avatarUrl}) result) async {
    final TextEditingController didController = TextEditingController();
    final scale = ref.read(uiScaleProvider);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ConsciaTheme.background(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24 * scale)),
        title: Text("Link your Identity", style: ConsciaTheme.headingStyle(context, scale)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We found your ${config.name} account (${result.sub}), but it isn't linked to a local persona yet.",
              style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: Colors.white70),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ConsciaTheme.accent(context),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                final service = ref.read(identityServiceProvider);
                final newDid = await service.createProfileFromOauth(
                  provider: config.id, 
                  sub: result.sub, 
                  name: result.displayName, 
                  avatar: result.avatarUrl
                );
                await ref.read(identityProvider.notifier).refreshManifest();
                await ref.read(identityProvider.notifier).switchIdentity(newDid);
              },
              child: Text("Create New Persona", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text("Or link to an existing one:", style: ConsciaTheme.subHeadingStyle(context, scale)),
            SizedBox(height: 8),
            TextField(
              controller: didController,
              decoration: ConsciaTheme.inputDecoration(context, "Paste your did:peer...", scale),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 44),
              ),
              onPressed: () async {
                final did = didController.text.trim();
                if (!did.startsWith("did:peer:")) {
                  widget.onToast("Invalid DID format", isError: true);
                  return;
                }
                Navigator.pop(context);
                try {
                  final service = ref.read(identityServiceProvider);
                  await service.linkOauthToExistingProfile(did: did, provider: config.id, sub: result.sub);
                  await ref.read(identityProvider.notifier).refreshManifest();
                  await ref.read(identityProvider.notifier).switchIdentity(did);
                } catch (e) {
                  widget.onToast("Linking failed: $e", isError: true);
                }
              },
              child: Text("Link to this Persona"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scale = ref.watch(uiScaleProvider);
    final identityState = ref.watch(identityProvider);
    final bool isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      backgroundColor: ConsciaTheme.background(context),
      body: CallbackShortcuts(
        bindings: {
          SingleActivator(LogicalKeyboardKey.enter): () => _menuController.open(),
          SingleActivator(LogicalKeyboardKey.space): () => _menuController.open(),
          // Dev shortcut: CTRL+1 — sign in as the first autonomous identity
          SingleActivator(LogicalKeyboardKey.digit1, control: true): () {
            final identities = ref.read(identityProvider).knownIdentities;
            if (identities.isNotEmpty) {
              debugPrint('[DEV] CTRL+1: Signing in as ${identities.first.displayName}');
              ref.read(identityProvider.notifier).switchIdentity(identities.first.did);
            } else {
              debugPrint('[DEV] CTRL+1: No identities available.');
            }
          },
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ConsciaTheme.mainGradient(context),
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 * scale : 24.0 * scale, vertical: 32.0 * scale),
                child: Container(
                  key: const Key('welcome_screen_card'),
                  // EDUCATIONAL CONTEXT: Fixed Frame Layout (Spec 17)
                  // We apply a fixed frame via constraints scaled 
                  // by 'uiScaleProvider'. This ensures that the onboarding 
                  // experience remains consistent regardless of window size.
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 0 : 440.0 * scale,
                    maxWidth: isMobile ? double.infinity : 600.0 * scale,
                  ),
                  padding: EdgeInsets.all(isMobile ? 24.0 * scale : 40.0 * scale),
                  decoration: ConsciaTheme.premiumCardDecoration(context, scale),
                  child: Builder(
                    builder: (context) {
                      final identities = identityState.knownIdentities;
                      
                      final double titleSize = isMobile ? 28.0 * scale : 32.0 * scale;
                      final double iconSize = isMobile ? 42.0 * scale : 56.0 * scale;
                      final double headerGap = isMobile ? 16.0 : 24.0;
                      
                      List<TrackSize> rowSizes = [auto, 8.px, auto, 8.px, auto, headerGap.px];
                      List<Widget> gridChildren = [
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 16.0 * scale : 24.0 * scale),
                            decoration: BoxDecoration(color: ConsciaTheme.accentDark(context), shape: BoxShape.circle),
                            child: Icon(LucideIcons.globe, size: iconSize, color: ConsciaTheme.accent(context)),
                          ),
                        ).withGridPlacement(columnStart: 0, rowStart: 0),
                        const SizedBox().withGridPlacement(columnStart: 0, rowStart: 1),
                        Center(
                          child: Text("Welcome to ExoTalk", textAlign: TextAlign.center, style: ConsciaTheme.headingStyle(context, scale).copyWith(fontSize: titleSize))
                        ).withGridPlacement(columnStart: 0, rowStart: 2),
                        const SizedBox().withGridPlacement(columnStart: 0, rowStart: 3),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 400.0 * scale),
                            child: Text(
                              "Your private, peer-to-peer workspace is ready.\nHow would you like to get started?",
                              textAlign: TextAlign.center,
                              style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: ConsciaTheme.muted(context), height: 1.6),
                            ),
                          ),
                        ).withGridPlacement(columnStart: 0, rowStart: 4),
                        const SizedBox().withGridPlacement(columnStart: 0, rowStart: 5),
                      ];

                      int currentRow = 6;

                      if (identities.isNotEmpty) {
                        rowSizes.addAll([auto, 12.px, auto, 12.px]);
                        gridChildren.add(Center(
                          child: Text("REGISTERED IDENTITIES", textAlign: TextAlign.center, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: ConsciaTheme.accent(context)))
                        ).withGridPlacement(columnStart: 0, rowStart: currentRow++));
                        gridChildren.add(SizedBox().withGridPlacement(columnStart: 0, rowStart: currentRow++));
                        gridChildren.add(Center(
                          child: Wrap(
                            spacing: 16.0 * scale,
                            runSpacing: 16.0 * scale,
                            alignment: WrapAlignment.center,
                            children: identities.map((identity) {
                              return _IdentityItem(identity: identity, scale: scale);
                            }).toList(),
                          ),
                        ).withGridPlacement(columnStart: 0, rowStart: currentRow++));
                        gridChildren.add(SizedBox().withGridPlacement(columnStart: 0, rowStart: currentRow++));
                        
                        rowSizes.add(auto);
                        gridChildren.add(const Divider().withGridPlacement(columnStart: 0, rowStart: currentRow++));
                        rowSizes.add(12.px);
                        gridChildren.add(SizedBox().withGridPlacement(columnStart: 0, rowStart: currentRow++));
                      }

                      rowSizes.add(auto);
                      gridChildren.add(Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 320.0 * scale),
                          child: _OnboardingMenu(
                            scale: scale, 
                            controller: _menuController,
                            onCreateIdentity: widget.onCreateIdentity,
                            onLinkDevice: widget.onLinkDevice,
                          ),
                        ),
                      ).withGridPlacement(columnStart: 0, rowStart: currentRow++));
                      
                      rowSizes.add(24.px); 
                      gridChildren.add(SizedBox().withGridPlacement(columnStart: 0, rowStart: currentRow++));

                      rowSizes.add(auto);
                      gridChildren.add(LayoutGrid(
                        columnSizes: [1.fr, auto, 1.fr],
                        rowSizes: const [auto],
                        columnGap: 20.0 * scale,
                        children: [
                          const Divider().withGridPlacement(columnStart: 0, rowStart: 0),
                          Text("OR LINK PROVIDER", textAlign: TextAlign.center, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)).withGridPlacement(columnStart: 1, rowStart: 0),
                          const Divider().withGridPlacement(columnStart: 2, rowStart: 0),
                        ],
                      ).withGridPlacement(columnStart: 0, rowStart: currentRow++));

                      rowSizes.add(24.px);
                      gridChildren.add(SizedBox().withGridPlacement(columnStart: 0, rowStart: currentRow++));

                      rowSizes.add(auto);
                      gridChildren.add(Center(
                        child: _OAuthSection(scale: scale)
                      ).withGridPlacement(columnStart: 0, rowStart: currentRow++));

                      return LayoutGrid(
                        columnSizes: [1.fr],
                        rowSizes: rowSizes,
                        children: gridChildren,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingMenu extends ConsumerStatefulWidget {
  final double scale;
  final MenuController controller;
  final VoidCallback onCreateIdentity;
  final VoidCallback onLinkDevice;

  const _OnboardingMenu({
    required this.scale, 
    required this.controller,
    required this.onCreateIdentity,
    required this.onLinkDevice,
  });

  @override
  ConsumerState<_OnboardingMenu> createState() => _OnboardingMenuState();
}

class _OnboardingMenuState extends ConsumerState<_OnboardingMenu> {
  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    return MenuAnchor(
      controller: widget.controller,
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(ConsciaTheme.surfaceElevated(context)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * scale), side: BorderSide(color: ConsciaTheme.border(context)))),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(LucideIcons.plus, size: 18 * scale),
          onPressed: widget.onCreateIdentity,
          child: Text("Create New Identity", style: ConsciaTheme.bodyStyle(context, scale)),
        ),
        MenuItemButton(
          leadingIcon: Icon(LucideIcons.link, size: 18 * scale),
          onPressed: widget.onLinkDevice,
          child: Text("Link Existing Device", style: ConsciaTheme.bodyStyle(context, scale)),
        ),
      ],
      child: ElevatedButton.icon(
        onPressed: () => widget.controller.open(),
        style: ElevatedButton.styleFrom(
          backgroundColor: ConsciaTheme.accent(context),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56 * scale),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * scale)),
          elevation: 4,
        ),
        icon: Icon(LucideIcons.plus, size: 20 * scale),
        label: Text("ADD IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2 * scale)),
      ),
    );
  }
}

class _IdentityItem extends ConsumerWidget {
  final ProfileRecord identity;
  final double scale;

  const _IdentityItem({required this.identity, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 220.0 * scale,
      child: TextButton(
        onPressed: () {
          debugPrint("UI: Clicking identity ${identity.displayName}");
          ref.read(identityProvider.notifier).switchIdentity(identity.did);
        },
        style: TextButton.styleFrom(
          backgroundColor: ConsciaTheme.surfaceElevated(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0 * scale),
            side: BorderSide(color: ConsciaTheme.accent(context).withValues(alpha: 0.4), width: 1.5),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 20.0 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14.0 * scale, 
              backgroundColor: ConsciaTheme.accent(context), 
              child: Text(identity.displayName.isNotEmpty ? identity.displayName[0] : '?', style: TextStyle(fontSize: 12.0 * scale, fontWeight: FontWeight.bold, color: Colors.white))
            ),
            SizedBox(width: 12.0 * scale),
            Flexible(
              child: Text(
                identity.displayName.isNotEmpty ? identity.displayName : "New Identity", 
                style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.text(context), fontWeight: FontWeight.bold, fontSize: 13.0 * scale),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OAuthSection extends StatelessWidget {
  final double scale;
  const _OAuthSection({required this.scale});

  @override
  Widget build(BuildContext context) {
    final googleConfig = OAuthService.builtInProviders['google']!;
    final githubConfig = OAuthService.builtInProviders['github']!;

    return Column(
      children: [
        _OAuthButton(config: googleConfig, icon: LucideIcons.chrome, scale: scale),
        SizedBox(height: 12 * scale),
        _OAuthButton(config: githubConfig, icon: LucideIcons.github, scale: scale),
      ],
    );
  }
}

class _OAuthButton extends ConsumerWidget {
  final OAuthProviderConfig config;
  final IconData icon;
  final double scale;
  const _OAuthButton({required this.config, required this.icon, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => (context.findAncestorStateOfType<_ExoAuthViewState>())?._linkAndLogin(config),
      icon: Icon(icon, size: 20 * scale),
      label: Text("Sign in with ${config.name}", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: ConsciaTheme.surfaceElevated(context),
        foregroundColor: ConsciaTheme.text(context),
        minimumSize: Size(double.infinity, 50 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          side: BorderSide(color: ConsciaTheme.border(context)),
        ),
        elevation: 0,
      ),
    );
  }
}
