// =============================================================================
// device_pairing_modal.dart — Cross-Device Identity Transfer ("Outward Recovery")
// =============================================================================
//
// This modal enables identity portability across devices. It implements TWO
// complementary transfer mechanisms:
//
//   1. **QR Code Pairing** — A short-lived, ed25519-signed token is encoded
//      into a QR code. Scanning it on a second device establishes a secure
//      link for real-time identity sync.
//
//   2. **Manual Bundle Transfer** — The full identity vault (keypair, display
//      name, OAuth links, verified links) is exported as a signed JSON blob.
//      The user can copy-paste it between devices for offline migration.
//
// ARCHITECTURAL NOTE — Backend Agnosticism:
//   All cryptographic operations (token generation, bundle export/import,
//   signature verification) are delegated to [IdentityService]. This modal
//   has ZERO knowledge of whether the backend is Rust FFI, a web API, or a
//   test mock. The only contract it relies on is the abstract interface.
//
// See: docs/spec/02_identity_and_access.md §2.5 for the pairing protocol.
// =============================================================================

import '../theme.dart';
import '../providers.dart';
import '../identity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
class DevicePairingModal extends ConsumerStatefulWidget {
  final int startTab;
  const DevicePairingModal({super.key, this.startTab = 0});

  @override
  ConsumerState<DevicePairingModal> createState() => _DevicePairingModalState();
}

class _DevicePairingModalState extends ConsumerState<DevicePairingModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _pairingToken;
  String? _bundle;
  bool _isLoading = false;
  String? _error;
  bool _importSuccess = false;

  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.startTab);
    _generateToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _generateToken() async {
    try {
      final token = await ref.read(identityServiceProvider).generateDevicePairingToken();
      final bundle = await ref.read(identityServiceProvider).exportProfileBundle();
      setState(() {
        _pairingToken = token;
        _bundle = bundle;
      });
    } catch (e) {
      setState(() => _error = "Failed to generate token: $e");
    }
  }

  Future<void> _handleImport() async {
    final input = _importController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref.read(identityServiceProvider).importProfileBundle(bundle: input);
      if (success) {
        await ref.read(identityProvider.notifier).refreshActiveVault();
        setState(() => _importSuccess = true);
      } else {
        setState(() => _error = "Invalid bundle or signature. Make sure the source device is authentic.");
      }
    } catch (e) {
      setState(() => _error = "Import failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(400.0, 500.0 * scale),
          maxHeight: 650.0 * scale,
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
                  Icon(LucideIcons.smartphone, color: ConsciaTheme.accent(context), size: 24.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Device Pairing", style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
                      Text("Sync your identity and links across devices.", style: ConsciaTheme.captionStyle(context, scale)),
                    ],
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(LucideIcons.x, size: 18.0 * scale, color: ConsciaTheme.muted(context))).withGridPlacement(columnStart: 2, rowStart: 0),
                ],
              ),
            ),

            TabBar(
              controller: _tabController,
              labelColor: ConsciaTheme.accent(context),
              unselectedLabelColor: ConsciaTheme.muted(context),
              indicatorColor: ConsciaTheme.accent(context),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "From This Device"),
                Tab(text: "Into This Device"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSourceTab(scale),
                  _buildDestinationTab(scale),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceTab(double scale) {
    if (_pairingToken == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(32.0 * scale),
      child: Column(
        children: [
          Text(
            "Scan this code to establish a secure link, or use the manual transfer bundle below for a one-shot migration.",
            textAlign: TextAlign.center,
            style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: ConsciaTheme.muted(context)),
          ),
          SizedBox(height: 24.0 * scale),
          Container(
            padding: EdgeInsets.all(16.0 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0 * scale),
              border: Border.all(color: ConsciaTheme.border(context)),
            ),
            child: QrImageView(
              data: _pairingToken ?? "",
              version: QrVersions.auto,
              size: 200.0 * scale,
            ),
          ),
          SizedBox(height: 24.0 * scale),
          Text("Or copy the full transfer bundle:", style: TextStyle(fontSize: 11 * scale, fontWeight: FontWeight.bold, color: ConsciaTheme.muted(context))),
          SizedBox(height: 8.0 * scale),
          Container(
            padding: EdgeInsets.all(12.0 * scale),
            decoration: BoxDecoration(
              color: ConsciaTheme.hover(context),
              borderRadius: BorderRadius.circular(12.0 * scale),
            ),
            child: LayoutGrid(
              columnSizes: [1.fr, auto],
              rowSizes: [auto],
              columnGap: 8.0 * scale,
              children: [
                Text(
                  _bundle ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 10 * scale),
                ).withGridPlacement(columnStart: 0, rowStart: 0),
                IconButton(
                  icon: Icon(LucideIcons.copy, size: 16.0 * scale, color: ConsciaTheme.muted(context)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _bundle ?? ""));
                    ref.read(authToastProvider)("Pairing details copied.", isError: false);
                  },
                ).withGridPlacement(columnStart: 1, rowStart: 0),
              ],
            ),
          ),
          SizedBox(height: 16.0 * scale),
          LayoutGrid(
            columnSizes: [1.fr, auto, auto, 1.fr],
            rowSizes: [auto],
            columnGap: 8.0 * scale,
            children: [
              SizedBox().withGridPlacement(columnStart: 0, rowStart: 0),
              Icon(LucideIcons.lock, size: 12.0 * scale, color: Colors.green).withGridPlacement(columnStart: 1, rowStart: 0),
              Text("Encrypted & Signed by your did:peer key", style: TextStyle(fontSize: 10 * scale, color: Colors.green)).withGridPlacement(columnStart: 2, rowStart: 0),
              SizedBox().withGridPlacement(columnStart: 3, rowStart: 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationTab(double scale) {
    if (_importSuccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.checkCircle2, color: Colors.green, size: 64.0 * scale),
            SizedBox(height: 24.0 * scale),
            Text("Sync Successful!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scale, color: Colors.white)),
            SizedBox(height: 8.0 * scale),
            Text("Your identity has been restored on this device.", style: TextStyle(color: ConsciaTheme.muted(context))),
            SizedBox(height: 32.0 * scale),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ConsciaTheme.accent(context), 
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.0 * scale, vertical: 16.0 * scale),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
              ),
              child: Text("Go to Dashboard", style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(32.0 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paste the transfer bundle provided by your source device to restore your identity.",
            style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: ConsciaTheme.muted(context)),
          ),
          SizedBox(height: 20.0 * scale),
          TextField(
            controller: _importController,
            maxLines: 8,
            style: TextStyle(fontFamily: 'monospace', fontSize: 11 * scale),
            decoration: InputDecoration(
              hintText: "eyJhY2NvdW50X2J1bmRsZSI6ICJleHQ... ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0 * scale)),
              fillColor: ConsciaTheme.hover(context),
              filled: true,
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: 12.0 * scale),
            Text(_error!, style: TextStyle(color: Colors.red, fontSize: 11 * scale)),
          ],
          Spacer(),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleImport,
            icon: _isLoading 
              ? SizedBox(width: 16.0 * scale, height: 16.0 * scale, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(LucideIcons.download, size: 18.0 * scale),
            label: Text(_isLoading ? "Verifying..." : "Transfer Identity", style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ConsciaTheme.accent(context),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 56.0 * scale),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0 * scale)),
            ),
          ),
        ],
      ),
    );
  }
}
