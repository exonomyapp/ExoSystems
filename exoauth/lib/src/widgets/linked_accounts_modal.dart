// =============================================================================
// linked_accounts_modal.dart — OAuth Account Management ("Inward Recovery")
// =============================================================================
//
// This modal manages the user's linked OAuth accounts. These are "Recovery
// Anchors" — secondary sign-in methods that allow the user to regain access
// to their did:peer identity after losing a device.
//
// IMPORTANT: Linked accounts do NOT own the identity. The did:peer remains
// the sovereign root. OAuth providers are "Friends of the Identity" that can
// vouch for the user during a recovery flow on a Conscia node.
//
// UI layout:
//   - Grid of provider tiles (GitHub, Discord — currently built-in)
//   - "Pending Review" tiles for providers not yet integrated (Google, etc.)
//   - Linked providers show the associated display name and can be unlinked
//
// See: docs/spec/02_identity_and_access.md §2.4.2 for the recovery model.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../theme.dart';
import '../providers.dart';
import '../models.dart';
import '../identity_service.dart';


class LinkedAccountsModal extends ConsumerStatefulWidget {
  const LinkedAccountsModal({super.key});

  @override
  ConsumerState<LinkedAccountsModal> createState() => _LinkedAccountsModalState();
}

class _LinkedAccountsModalState extends ConsumerState<LinkedAccountsModal> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _linkProvider(OAuthProviderConfig config) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await OAuthService.authenticate(config);
      await ref.read(identityServiceProvider).addOauthLink(
        provider: config.id,
        displayName: result.displayName,
        sub: result.sub,
      );
      await ref.read(identityProvider.notifier).refreshActiveVault();
      if (mounted) {
        ref.read(authToastProvider)("Successfully linked ${config.name}!", isError: false);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    try {
      await ref.read(identityServiceProvider).removeOauthLink(providerId);
      await ref.read(identityProvider.notifier).refreshActiveVault();
    } catch (e) {
      ref.read(authToastProvider)("Could not disconnect this account. Please try again.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);
    final vault = ref.watch(identityProvider).activeVault!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.5).clamp(450.0, 700.0 * scale),
          maxHeight: 600.0 * scale,
        ),
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24.0 * scale),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ConsciaTheme.border(context))),
              ),
              child: LayoutGrid(
                columnSizes: [auto, 1.fr, auto],
                rowSizes: [auto],
                columnGap: 16.0 * scale,
                children: [
                  Icon(LucideIcons.fingerprint, color: ConsciaTheme.accent(context), size: 24.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Linked Accounts", style: ConsciaTheme.headingStyle(context, scale)),
                      Text("Secondary sign-in methods for this device.", style: ConsciaTheme.captionStyle(context, scale)),
                    ],
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: Icon(LucideIcons.x, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
                  ).withGridPlacement(columnStart: 2, rowStart: 0),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: EdgeInsets.all(16.0 * scale),
                padding: EdgeInsets.all(12.0 * scale),
                decoration: BoxDecoration(
                  color: ConsciaTheme.error(context).withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(12.0 * scale),
                  border: Border.all(color: ConsciaTheme.error(context).withValues(alpha: 0.3)),
                ),
                child: LayoutGrid(
                  columnSizes: [auto, 1.fr],
                  rowSizes: [auto],
                  columnGap: 8.0 * scale,
                  children: [
                    Icon(LucideIcons.alertTriangle, color: ConsciaTheme.error(context), size: 16.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                    Text(_errorMessage!, style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.error(context))).withGridPlacement(columnStart: 1, rowStart: 0),
                  ],
                ),
              ),

            // Provider Grid
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0 * scale),
                child: LayoutGrid(
                  columnSizes: [1.fr, 1.fr],
                  rowSizes: [auto, auto], 
                  columnGap: 16.0 * scale,
                  rowGap: 16.0 * scale,
                  children: [
                    ...OAuthService.builtInProviders.values.map((config) {
                      final link = vault.oauthLinks.cast<OAuthLink?>().firstWhere((l) => l?.provider == config.id, orElse: () => null);
                      return _ProviderTile(
                        config: config,
                        isLinked: link != null,
                        linkedLabel: link?.displayName,
                        onTap: () => link != null ? _unlinkProvider(config.id) : _linkProvider(config),
                        isLoading: _isLoading,
                        scale: scale,
                      );
                    }),
                    ...OAuthService.pendingReviewProviderIds.map((id) {
                      return _PendingProviderTile(id: id, scale: scale);
                    }),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(16.0 * scale),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: ConsciaTheme.border(context)))),
              child: LayoutGrid(
                columnSizes: [auto, 1.fr],
                rowSizes: [auto],
                columnGap: 12.0 * scale,
                children: [
                  Icon(LucideIcons.info, size: 14.0 * scale, color: ConsciaTheme.muted(context)).withGridPlacement(columnStart: 0, rowStart: 0),
                  Text(
                    "Linked accounts are stored locally and encrypted. They allow you to easily sign in on this device.",
                    style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.muted(context)),
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final OAuthProviderConfig config;
  final bool isLinked;
  final String? linkedLabel;
  final VoidCallback onTap;
  final bool isLoading;
  final double scale;

  const _ProviderTile({
    required this.config,
    required this.isLinked,
    this.linkedLabel,
    required this.onTap,
    required this.isLoading,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: isLinked ? ConsciaTheme.accent(context).withValues(alpha: 0.1) : ConsciaTheme.surface(context),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: isLinked ? ConsciaTheme.accent(context).withValues(alpha: 0.3) : ConsciaTheme.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              config.id == 'github' ? LucideIcons.github : 
              config.id == 'google' ? LucideIcons.globe :
              config.id == 'discord' ? LucideIcons.disc :
              LucideIcons.link,
              color: isLinked ? ConsciaTheme.accent(context) : ConsciaTheme.muted(context),
              size: 28 * scale,
            ),
            SizedBox(height: 12 * scale),
            Text(config.name, style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
            if (isLinked) ...[
              SizedBox(height: 4 * scale),
              Text(linkedLabel ?? "Linked", style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.accent(context), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ] else 
              Text("Click to link", style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.muted(context))),
          ],
        ),
      ),
    );
  }
}

class _PendingProviderTile extends StatelessWidget {
  final String id;
  final double scale;
  const _PendingProviderTile({required this.id, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: ConsciaTheme.background(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: ConsciaTheme.border(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.lock, color: ConsciaTheme.muted(context).withValues(alpha: 0.3), size: 24 * scale),
          SizedBox(height: 8 * scale),
          Text(id[0].toUpperCase() + id.substring(1), style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.muted(context), fontWeight: FontWeight.bold)),
          Text("Coming soon", style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.muted(context).withValues(alpha: 0.5), fontSize: 9 * scale)),
        ],
      ),
    );
  }
}
