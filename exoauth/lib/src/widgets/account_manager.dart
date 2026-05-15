// account_manager.dart — Identity Management
// =============================================================================
// This modal is the control surface for the user identity.
// It follows a two-column layout to surface identity
// and security controls.
// =============================================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../theme.dart';
import '../providers.dart';
import '../models.dart';
import '../identity_service.dart';
import '../services/oauth_service.dart';
import 'verify_identity_modal.dart';
import 'rename_confirm_dialog.dart';
import 'danger_zone.dart';
import 'device_pairing_modal.dart';

class AccountManagerModal extends ConsumerStatefulWidget {
  const AccountManagerModal({super.key});

  @override
  ConsumerState<AccountManagerModal> createState() => _AccountManagerModalState();
}

class _AccountManagerModalState extends ConsumerState<AccountManagerModal> {
  // The state below mirrors the programmatic IdentityRecord.
  // 'localName' and 'localAvatar' are pending metadata changes that only commit 
  // to the engine when _handleSync() is called.
  // ----------------------------

  String localName = "";
  late String localAvatar;
  Uint8List? localAvatarBytes;
  late String localDid;
  late String localPrivateKey;
  bool isGenerating = false;

  late TextEditingController nameController;
  late TextEditingController avatarController;

  @override
  void initState() {
    super.initState();
    final vault = ref.read(identityProvider).activeVault;
    localName = vault?.displayName ?? "";
    localAvatar = vault?.avatarUrl ?? "";
    localAvatarBytes = null;
    localDid = (vault?.did.contains("temp") ?? true) ? "" : vault!.did;
    localPrivateKey = vault?.secret ?? "";

    nameController = TextEditingController(text: localName);
    avatarController = TextEditingController(text: localAvatar);
    
    nameController.addListener(() => localName = nameController.text);
  }

  @override
  void dispose() {
    nameController.dispose();
    avatarController.dispose();
    super.dispose();
  }

  Future<void> handlePickImage() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'images', extensions: <String>['jpg', 'jpeg', 'png', 'gif', 'webp']);
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        localAvatarBytes = bytes;
        localAvatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        avatarController.text = "[Local Image]";
      });
    }
  }

  void handleRemoveImage() {
    setState(() {
      localAvatarBytes = null;
      localAvatar = "";
      avatarController.text = "";
    });
  }

  void copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ref.read(authToastProvider)("$label copied to clipboard.", isError: false);
  }

  Future<void> generateDidPeer() async {
    setState(() => isGenerating = true);
    try {
      final vault = await ref.read(identityServiceProvider).generateNewIdentity();
      await ref.read(identityProvider.notifier).switchIdentity(vault.did);
      await ref.read(identityProvider.notifier).refreshManifest();
      await ref.read(identityProvider.notifier).refreshActiveVault();
      setState(() {
        localDid = vault.did;
        localPrivateKey = vault.secret;
        isGenerating = false;
      });
      if (mounted) {
        ref.read(authToastProvider)("Your security keys have been refreshed.", isError: false);
      }
    } catch (e) {
      setState(() => isGenerating = false);
      if (mounted) {
        ref.read(authToastProvider)("Could not refresh your security keys. Please try again.", isError: true);
      }
    }
  }

  Future<void> _handleSync() async {
    final vault = ref.read(identityProvider).activeVault;
    final navigator = Navigator.of(context);
    if (vault != null && localName != vault.displayName) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => RenameConfirmDialog(oldName: vault.displayName, newName: localName, verifiedLinksCount: vault.verifiedLinks.length),
      );
      if (confirmed != true) return;
    }
    await ref.read(identityServiceProvider).updateActiveProfile(name: localName, avatar: localAvatar);
    await ref.read(identityProvider.notifier).refreshManifest();
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);
    final vault = ref.watch(identityProvider).activeVault;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _handleSync(),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _handleSync(),
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.of(context).size.width * 0.95).clamp(800.0, 1050.0 * scale), 
            maxHeight: 800.0 * scale,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: AppTheme.premiumCardDecoration(context, scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalHeader(scale: scale),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.0 * scale),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProfileSection(
                            localAvatarBytes: localAvatarBytes,
                            localAvatar: localAvatar,
                            avatarController: avatarController,
                            nameController: nameController,
                            onPickImage: handlePickImage,
                            onRemoveImage: handleRemoveImage,
                            profile: vault,
                            scale: scale,
                          ),
                          SizedBox(height: 24.0 * scale),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT: Security Keys
                              Expanded(
                                child: _SecurityKeysSection(
                                  did: localDid,
                                  secret: localPrivateKey,
                                  isGenerating: isGenerating,
                                  onRotate: generateDidPeer,
                                  onCopyDid: () => copyToClipboard(localDid, "DID"),
                                  onCopySecret: () => copyToClipboard(localPrivateKey, "Signing Secret"),
                                  scale: scale,
                                ),
                              ),
                              SizedBox(width: 20.0 * scale),
                              
                              // MIDDLE: Verified Identities
                              Expanded(
                                child: _IdentitySection(profile: vault, nameController: nameController, scale: scale),
                              ),
                              ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24.0 * scale),
                      Divider(),
                      SizedBox(height: 8.0 * scale),
                      DangerZone(
                        scale: scale,
                        items: [
                          DangerZoneItem(
                            title: "Discard Identity",
                            description: "Permanently wipes all local secrets and history. Your did:peer is decentralized and cannot be globally deleted.",
                            buttonLabel: "Discard Identity",
                            onPressed: () async {
                              final didToDiscard = localDid;
                              if (didToDiscard.isEmpty) return;

                              final navigator = Navigator.of(context);
                              await ref.read(identityProvider.notifier).discardIdentity(didToDiscard);
                              navigator.pop();
                              ref.read(authToastProvider)("Identity discarded permanently.", isError: false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _ModalFooter(
                onCancel: () => Navigator.pop(context),
                onSync: _handleSync,
                scale: scale,
                isNewIdentity: vault == null || (vault.did.contains("temp")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final double scale;
  const _ModalHeader({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 16.0 * scale),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border(context)))),
      child: LayoutGrid(
        columnSizes: [auto, auto, auto, auto, 1.fr, auto],
        rowSizes: [auto],
        columnGap: 12.0 * scale,
        children: [
          Icon(LucideIcons.shield, color: AppTheme.accent(context), size: 24.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
          Text("Account Manager", style: AppTheme.headingStyle(context, scale)).withGridPlacement(columnStart: 1, rowStart: 0),
          Container(width: 1, height: 16 * scale, color: AppTheme.border(context)).withGridPlacement(columnStart: 2, rowStart: 0),
          Text("Identity settings", 
            style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.muted(context))).withGridPlacement(columnStart: 3, rowStart: 0),
          SizedBox().withGridPlacement(columnStart: 4, rowStart: 0),
          Text("v0.7.6+1", style: AppTheme.versionStyle(context, scale)).withGridPlacement(columnStart: 5, rowStart: 0),
        ],
      ),
    );
  }
}


class _ProfileSection extends ConsumerWidget {
  final Uint8List? localAvatarBytes;
  final String localAvatar;
  final TextEditingController avatarController;
  final TextEditingController nameController;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final IdentityRecord? profile;
  final double scale;

  const _ProfileSection({
    required this.localAvatarBytes,
    required this.localAvatar,
    required this.avatarController,
    required this.nameController,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.profile,
    required this.scale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutGrid(
      columnSizes: [1.fr, 1.fr],
      rowSizes: const [auto],
      columnGap: 20.0 * scale,
      children: [
        // LEFT 50%: Identity Profile
        LayoutGrid(
          columnSizes: [auto, 1.fr],
          rowSizes: [auto],
          columnGap: 16.0 * scale,
          children: [
            _ConsciaMenuButton(
              scale: scale,
              isCircle: true,
              onPressed: () {},
              menuItems: [
                _MenuItem(icon: LucideIcons.camera, label: "Change Photo", onTap: onPickImage),
                _MenuItem(icon: LucideIcons.trash2, label: "Remove Photo", isDestructive: true, onTap: onRemoveImage),
              ],
              child: localAvatarBytes != null
                ? ClipOval(child: Image.memory(localAvatarBytes!, fit: BoxFit.cover, width: 80 * scale, height: 80 * scale))
                : Icon(LucideIcons.user, size: 32.0 * scale, color: AppTheme.muted(context)),
            ).withGridPlacement(columnStart: 0, rowStart: 0),
            _SectionWrapper(
              title: "Display Name",
              scale: scale,
              child: TextField(
                autofocus: true,
                controller: nameController,
                style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold),
                decoration: AppTheme.inputDecoration(context, "Enter display name", scale).copyWith(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 14.0 * scale),
                ),
              ),
            ).withGridPlacement(columnStart: 1, rowStart: 0),
          ],
        ).withGridPlacement(columnStart: 0, rowStart: 0),

        // RIGHT 50%: Network Sync Controls
        _SectionWrapper(
          title: "Network Sync",
          scale: scale,
          action: TextButton.icon(
            onPressed: () => showDialog(context: context, builder: (_) => DevicePairingModal()),
            icon: Icon(LucideIcons.smartphone, size: 14.0 * scale),
            label: Text("Pair", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold)),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 8.0 * scale),
            decoration: BoxDecoration(
              color: AppTheme.background(context), 
              borderRadius: BorderRadius.circular(12.0 * scale), 
              border: Border.all(color: AppTheme.border(context).withValues(alpha: 0.5))
            ),
            child: LayoutGrid(
              columnSizes: [1.fr, auto, 1.fr],
              rowSizes: [auto],
              children: [
                _SyncToggle(
                  label: "Receive sync",
                  value: profile?.ingressEnabled ?? false,
                  onChanged: profile == null ? null : (val) async {
                    await ref.read(identityServiceProvider).setIngressEnabled(enabled: val);
                    ref.read(identityProvider.notifier).refreshActiveVault();
                  },
                  scale: scale,
                ).withGridPlacement(columnStart: 0, rowStart: 0),
                Container(width: 1, height: 20 * scale, margin: EdgeInsets.symmetric(horizontal: 12 * scale), color: AppTheme.border(context).withValues(alpha: 0.5))
                    .withGridPlacement(columnStart: 1, rowStart: 0),
                _SyncToggle(
                  label: "Broadcast sync",
                  value: profile?.egressEnabled ?? false,
                  onChanged: profile == null ? null : (val) async {
                    await ref.read(identityServiceProvider).setEgressEnabled(enabled: val);
                    ref.read(identityProvider.notifier).refreshActiveVault();
                  },
                  scale: scale,
                ).withGridPlacement(columnStart: 2, rowStart: 0),
              ],
            ),
          ),
        ).withGridPlacement(columnStart: 1, rowStart: 0),
      ],
    );
  }
}

class _IdentitySection extends ConsumerStatefulWidget {
  final IdentityRecord? profile;
  final TextEditingController nameController;
  final double scale;
  const _IdentitySection({required this.profile, required this.nameController, required this.scale});

  @override
  ConsumerState<_IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends ConsumerState<_IdentitySection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _canScrollLeft = _scrollController.offset > 0;
      _canScrollRight = _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final profile = widget.profile;

    return _SectionWrapper(
      title: "Verified Identities",
      action: TextButton.icon(
        icon: Icon(LucideIcons.plus, size: 14.0 * scale),
        label: Text("Add Link", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold)),
        onPressed: profile == null ? null : () async {
          final newName = widget.nameController.text.trim();
          if (newName.isNotEmpty) {
            await ref.read(identityServiceProvider).updateActiveProfile(
              name: newName, 
              avatar: profile!.avatarUrl
            );
          }
          if (context.mounted) {
            showDialog(context: context, builder: (_) => const VerifyIdentityModal());
          }
        },
      ),
      scale: scale,
      child: Container(
        height: 70.0 * scale,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background(context), 
          borderRadius: BorderRadius.circular(12.0 * scale), 
          border: Border.all(color: AppTheme.border(context))
        ),
        child: (profile == null || profile!.verifiedLinks.isEmpty)
          ? Center(child: Text("No verified links", style: AppTheme.captionStyle(context, scale)))
          : Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 8.0 * scale),
                  itemCount: profile.verifiedLinks.length,
                  itemBuilder: (context, index) {
                    final link = profile.verifiedLinks[index];
                    IconData icon = LucideIcons.link;
                    if (link.platformLabel.toLowerCase().contains('twitter')) {
                      icon = LucideIcons.twitter;
                    } else if (link.platformLabel.toLowerCase().contains('github')) {
                      icon = LucideIcons.github;
                    } else if (link.platformLabel.toLowerCase().contains('facebook')) {
                      icon = LucideIcons.facebook;
                    }

                    return _ConsciaMenuButton(
                      scale: scale,
                      isCircle: false,
                      onPressed: () {},
                      menuItems: [
                        _MenuItem(icon: LucideIcons.eye, label: "View", onTap: () {
                          showDialog(context: context, builder: (_) => _ViewProofModal(link: link, scale: scale));
                        }),
                        _MenuItem(icon: LucideIcons.trash2, label: "Remove", isDestructive: true, onTap: () {
                          ref.read(authToastProvider)("Link removal initiated", isError: false);
                        }),
                      ],
                      child: Center(
                        child: Icon(icon, size: 24.0 * scale, color: AppTheme.accent(context)),
                      ),
                    );
                  },
                ),
                if (_canScrollLeft)
                  Positioned(
                    left: 4 * scale, top: 0, bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(LucideIcons.chevronLeft, size: 14 * scale, color: Colors.white),
                        onPressed: () => _scrollController.animateTo(_scrollController.offset - 64 * scale, duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
                      ),
                    ),
                  ),
                if (_canScrollRight)
                  Positioned(
                    right: 4 * scale, top: 0, bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Icon(LucideIcons.chevronRight, size: 14 * scale, color: Colors.white),
                        onPressed: () => _scrollController.animateTo(_scrollController.offset + 64 * scale, duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});
}

class _ConsciaMenuButton extends StatefulWidget {
  final Widget child;
  final List<_MenuItem> menuItems;
  final VoidCallback onPressed;
  final bool isCircle;
  final double scale;

  const _ConsciaMenuButton({
    required this.child,
    required this.menuItems,
    required this.onPressed,
    required this.isCircle,
    required this.scale,
  });

  @override
  State<_ConsciaMenuButton> createState() => _ConsciaMenuButtonState();
}

class _ConsciaMenuButtonState extends State<_ConsciaMenuButton> {
  final MenuController _menuController = MenuController();
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final outerPadH = 2.0 * scale;
    final outerPadV = 1.0 * scale;
    final innerPadH = 6.0 * scale;
    final innerPadV = 3.0 * scale;

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: Offset(0, 4), 
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF1E293B)),
        elevation: WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
            side: BorderSide(color: AppTheme.border(context)),
          ),
        ),
        maximumSize: WidgetStatePropertyAll(Size(140.0 * scale, double.infinity)),
        padding: WidgetStatePropertyAll(EdgeInsets.all(4.0 * scale)),
      ),
      menuChildren: widget.menuItems.map((item) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: outerPadH, vertical: outerPadV),
          child: MenuItemButton(
            onPressed: item.onTap,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) return AppTheme.hover(context);
                return Colors.transparent;
              }),
              padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: innerPadH, vertical: innerPadV)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0 * scale))),
            ),
            child: LayoutGrid(
              columnSizes: [auto, 1.fr],
              rowSizes: [auto],
              columnGap: 8.0 * scale,
              children: [
                Icon(item.icon, size: 14 * scale, color: item.isDestructive ? AppTheme.error(context) : AppTheme.muted(context)).withGridPlacement(columnStart: 0, rowStart: 0),
                Text(item.label, 
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.captionStyle(context, scale).copyWith(
                    color: item.isDestructive ? AppTheme.error(context) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ).withGridPlacement(columnStart: 1, rowStart: 0),
              ],
            ),
          ),
        );
      }).toList(),
      builder: (context, controller, child) {
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: Duration(milliseconds: 100),
            child: Container(
              width: (widget.isCircle ? 80.0 : 52.0) * scale,
              height: (widget.isCircle ? 80.0 : 52.0) * scale,
              margin: EdgeInsets.only(right: widget.isCircle ? 0 : 12.0 * scale),
              decoration: BoxDecoration(
                color: _isPressed ? AppTheme.hover(context) : AppTheme.surface(context),
                shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.isCircle ? null : BorderRadius.circular(12.0 * scale),
                border: Border.all(color: _isPressed ? AppTheme.accent(context) : AppTheme.border(context)),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}


class _SyncToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool)? onChanged;
  final double scale;

  const _SyncToggle({required this.label, required this.value, required this.onChanged, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0 * scale),
      child: LayoutGrid(
        columnSizes: [1.fr, auto],
        rowSizes: [auto],
        children: [
          Text(label, style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold)).withGridPlacement(columnStart: 0, rowStart: 0),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    );
  }
}

class _SecurityKeysSection extends StatelessWidget {
  final String did;
  final String secret;
  final bool isGenerating;
  final VoidCallback onRotate;
  final VoidCallback onCopyDid;
  final VoidCallback onCopySecret;
  final double scale;

  const _SecurityKeysSection({required this.did, required this.secret, required this.isGenerating, required this.onRotate, required this.onCopyDid, required this.onCopySecret, required this.scale});

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      title: "Security Keys",
      action: TextButton.icon(
        onPressed: isGenerating ? null : onRotate,
        icon: isGenerating 
          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent(context)))
          : Icon(LucideIcons.refreshCw, size: 12.0 * scale, color: AppTheme.accent(context)),
        label: Text("Generate", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold)),
      ),
      scale: scale,
      child: Container(
        height: 70.0 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 10.0 * scale),
        decoration: BoxDecoration(color: AppTheme.background(context), borderRadius: BorderRadius.circular(12.0 * scale), border: Border.all(color: AppTheme.border(context))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100.0 * scale,
                  child: Row(
                    children: [
                      Icon(LucideIcons.fingerprint, color: AppTheme.accent(context), size: 16.0 * scale),
                      SizedBox(width: 8.0 * scale),
                      Text("Identifier", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: AppTheme.accent(context))),
                    ],
                  ),
                ),
                SizedBox(width: 8.0 * scale),
                Expanded(
                  child: Text(did, style: AppTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 8.0 * scale),
                IconButton(padding: EdgeInsets.zero, constraints: BoxConstraints(), icon: Icon(LucideIcons.copy, size: 14.0 * scale, color: AppTheme.muted(context)), onPressed: onCopyDid),
              ],
            ),
            SizedBox(height: 6.0 * scale),
            Row(
              children: [
                SizedBox(
                  width: 100.0 * scale,
                  child: Text("Signing Secret", style: AppTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 8.0 * scale),
                Expanded(
                  child: Text("••••••••••••••••••••••••••••••••", style: AppTheme.bodyStyle(context, scale).copyWith(fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 8.0 * scale),
                IconButton(padding: EdgeInsets.zero, constraints: BoxConstraints(), icon: Icon(LucideIcons.copy, size: 14.0 * scale, color: AppTheme.muted(context)), onPressed: onCopySecret),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class _ModalFooter extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSync;
  final double scale;
  final bool isNewIdentity;

  const _ModalFooter({required this.onCancel, required this.onSync, required this.scale, this.isNewIdentity = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.0 * scale),
      decoration: BoxDecoration(color: AppTheme.surface(context), border: Border(top: BorderSide(color: AppTheme.border(context)))),
      child: LayoutGrid(
        columnSizes: [1.fr, auto, auto],
        rowSizes: [auto],
        children: [
          SizedBox().withGridPlacement(columnStart: 0, rowStart: 0),
          TextButton(
            onPressed: onCancel, 
            child: Text("Cancel", style: AppTheme.bodyStyle(context, scale).copyWith(color: AppTheme.muted(context))),
          ).withGridPlacement(columnStart: 1, rowStart: 0),
          Padding(
            padding: EdgeInsets.only(left: 16.0 * scale),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent(context), 
                foregroundColor: Colors.white, 
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 18.0 * scale), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
              ),
              onPressed: onSync,
              child: Text(isNewIdentity ? "Save Identity" : "Save Changes", style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ).withGridPlacement(columnStart: 2, rowStart: 0),
        ],
      ),
    );
  }
}
class _SectionWrapper extends StatelessWidget {
  final String title;
  final Widget? action;
  final Widget child;
  final double scale;

  const _SectionWrapper({
    required this.title,
    this.action,
    required this.child,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: AppTheme.subHeadingStyle(context, scale).copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) 
                Padding(
                  padding: EdgeInsets.only(left: 8.0 * scale),
                  child: action!,
                ),
            ],
          ),
        ),
        SizedBox(height: 8.0 * scale),
        child,
      ],
    );
  }
}

class _ViewProofModal extends ConsumerWidget {
  final VerifiedLink link;
  final double scale;
  const _ViewProofModal({required this.link, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(350.0, 450.0 * scale),
        ),
        padding: EdgeInsets.all(24.0 * scale),
        decoration: AppTheme.premiumCardDecoration(context, scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Identity Proof", style: AppTheme.headingStyle(context, scale)),
            SizedBox(height: 24.0 * scale),
            Text("Verification URL", style: AppTheme.captionStyle(context, scale)),
            SizedBox(height: 8.0 * scale),
            Container(
              padding: EdgeInsets.all(12.0 * scale),
              decoration: BoxDecoration(
                color: AppTheme.background(context),
                borderRadius: BorderRadius.circular(12.0 * scale),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: LayoutGrid(
                columnSizes: [1.fr, auto],
                rowSizes: [auto],
                columnGap: 8.0 * scale,
                children: [
                  Text(
                    link.url,
                    style: AppTheme.bodyStyle(context, scale).copyWith(fontFamily: 'monospace', fontSize: 12.0 * scale),
                    overflow: TextOverflow.ellipsis,
                  ).withGridPlacement(columnStart: 0, rowStart: 0),
                  IconButton(
                    icon: Icon(LucideIcons.copy, size: 16.0 * scale, color: AppTheme.muted(context)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link.url));
                      ref.read(authToastProvider)("Proof URL copied.", isError: false);
                    },
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                ],
              ),
            ),
            SizedBox(height: 24.0 * scale),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Close", style: AppTheme.bodyStyle(context, scale).copyWith(color: AppTheme.accent(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





