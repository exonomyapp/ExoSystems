// =============================================================================
// verify_identity_modal.dart — Cryptographic Platform Linking ("Trust Web")
// =============================================================================
//
// This modal implements a 3-step wizard for linking a did:peer identity to
// external platforms (GitHub, Twitter/X, Mastodon, etc.) via publicly
// verifiable cryptographic proofs.
//
// THE FLOW:
//   Step 1 — Select Platform: The user picks where they'll post their proof.
//            The platform choice affects the character limit (e.g., Twitter
//            is capped at 160 chars, triggering a compact proof format).
//
//   Step 2 — Copy Proof String: A signed proof is generated via
//            [IdentityService.generateBestProof]. The proof format is
//            automatically selected to fit within the character limit:
//              • etp1:{PUBKEY}.{SIG}    — Full Compact (≤500 chars)
//              • ets1:{SIG}             — Minimal Signature (≤160 chars)
//              • exotalk-proof:v1:...   — Legacy Verbose (fallback)
//
//   Step 3 — Submit URL: The user pastes the URL where they published the
//            proof. The modal performs an HTTP GET, searches for the proof
//            string in the response body, and calls
//            [IdentityService.confirmVerificationLink] with the result.
//
// ARCHITECTURAL NOTE — Backend Agnosticism:
//   The HTTP verification (step 3) happens in-widget because it's a
//   pure network check with no persistence side-effects. The actual
//   vault mutation (adding/confirming the link) is always delegated
//   to IdentityService, keeping this modal backend-agnostic.
//
// See: docs/walkthroughs/06_compact_identity_proofs.md for proof format details.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../theme.dart';
import '../providers.dart';
import '../models.dart';
import '../identity_service.dart';


class VerifyIdentityModal extends ConsumerStatefulWidget {
  const VerifyIdentityModal({super.key});

  @override
  ConsumerState<VerifyIdentityModal> createState() => _VerifyIdentityModalState();
}

class _VerifyIdentityModalState extends ConsumerState<VerifyIdentityModal> {
  int _step = 0; // 0=select platform, 1=loading/generating, 2=show proof, 3=enter URL, 4=result
  String _proofString = '';
  String _errorMessage = '';
  bool _isChecking = false;
  bool _verifiedSuccess = false;
  String _selectedPlatform = 'GitHub';
  int _maxProofLen = 160;
  final _urlController = TextEditingController();
  final _limitController = TextEditingController(text: '160');
  final _limitFocusNode = FocusNode();

  final List<String> _platforms = [
    'GitHub',
    'Mastodon',
    'Twitter/X',
    'Facebook',
    'LinkedIn',
    'Personal Website',
    'Pastebin',
    'DNS TXT',
    'Other'
  ];

  @override
  void dispose() {
    _urlController.dispose();
    _limitController.dispose();
    _limitFocusNode.dispose();
    super.dispose();
  }

  Future<void> _generateProof() async {
    setState(() => _step = 1);
    try {
      final proof = await ref.read(identityServiceProvider).generateBestProof(platform: _selectedPlatform, maxChars: BigInt.from(_maxProofLen));
      setState(() {
        _proofString = proof;
        _step = 2;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _step = -1; // Error state
      });
    }
  }

  Future<void> _checkProof() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isChecking = true);
    try {
      // 1. Add as pending link in Rust
      await ref.read(identityServiceProvider).addVerificationLink(platformLabel: _selectedPlatform, url: url);

      // 2. Perform network check
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      final body = response.body;
      final found = body.contains(_proofString);

      // 3. Confirm result in Rust
      await ref.read(identityServiceProvider).confirmVerificationLink(url: url, verified: found);
      
      // Refresh UI state from vault
      await ref.read(identityProvider.notifier).refreshActiveVault();

      setState(() {
        _verifiedSuccess = found;
        _isChecking = false;
        _step = 4;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not fetch URL: $e';
        _verifiedSuccess = false;
        _isChecking = false;
        _step = 4;
      });
    }
  }

  Widget _buildStep0(double scale) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepBadge("Step 1 of 3", "Select Platform", scale),
      SizedBox(height: 12 * scale),
      Text(
        "Where will you be posting your identity proof?",
        style: ConsciaTheme.captionStyle(context, scale),
      ),
      SizedBox(height: 20 * scale),
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12 * scale,
          mainAxisSpacing: 12 * scale,
          childAspectRatio: 1.2,
        ),
        itemCount: _platforms.length,
        itemBuilder: (context, index) {
          final platform = _platforms[index];
          final isSelected = _selectedPlatform == platform;
          return _PlatformTile(
            platform: platform,
            isSelected: isSelected,
            scale: scale,
            onTap: () {
              setState(() {
                _selectedPlatform = platform;
                if (platform == 'Twitter/X') {
                  _maxProofLen = 160;
                } else if (platform == 'Personal Website') {
                  _maxProofLen = 100;
                } else {
                  _maxProofLen = 500;
                }
                _limitController.text = _maxProofLen.toString();
              });
            },
          );
        },
      ),
    ],
  );

  Widget _buildLoading() => Padding(
    padding: EdgeInsets.all(48),
    child: Center(child: CircularProgressIndicator()),
  );

  void _incrementLimit() {
    setState(() {
      _maxProofLen++;
      _limitController.text = _maxProofLen.toString();
    });
    _generateProof();
  }

  void _decrementLimit() {
    if (_maxProofLen > 1) {
      setState(() {
        _maxProofLen--;
        _limitController.text = _maxProofLen.toString();
      });
      _generateProof();
    }
  }

  String _getProofTypeLabel() {
    if (_proofString.startsWith('etp1:')) return 'Full Compact';
    if (_proofString.startsWith('ets1:')) return 'Minimal Signature';
    if (_proofString.startsWith('exotalk-proof:')) return 'Legacy (Verbose)';
    return 'Unknown Format';
  }

  Widget _buildError(double scale) => Padding(
    padding: EdgeInsets.all(32 * scale),
    child: Column(children: [
      Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 48 * scale),
      SizedBox(height: 16 * scale),
      Text(
        _errorMessage, 
        textAlign: TextAlign.center, 
        style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: Colors.white),
      ),
    ]),
  );

  Widget _buildStep2(double scale) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepBadge("Step 2 of 3", "Copy Proof String", scale),
      SizedBox(height: 12 * scale),
      Text(
        (_selectedPlatform == 'Twitter/X' || _selectedPlatform == 'Facebook')
            ? "Paste this proof into your bio or 'About' section."
            : "Post this cryptographic proof publicly on $_selectedPlatform.",
        style: ConsciaTheme.captionStyle(context, scale),
      ),
      SizedBox(height: 16 * scale),
      
      // Proof box
      Container(
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: ConsciaTheme.background(context),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: ConsciaTheme.border(context)),
        ),
        child: Column(
          children: [
            LayoutGrid(
              columnSizes: [1.fr, auto],
              rowSizes: [auto],
              columnGap: 8 * scale,
              children: [
                SelectableText(
                  _proofString,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11 * scale, height: 1.4, color: ConsciaTheme.accent(context)),
                ).withGridPlacement(columnStart: 0, rowStart: 0),
                IconButton(
                  icon: Icon(LucideIcons.copy, size: 18 * scale, color: ConsciaTheme.accent(context)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _proofString));
                    ref.read(authToastProvider)("Proof copied.", isError: false);
                  },
                ).withGridPlacement(columnStart: 1, rowStart: 0),
              ],
            ),
            SizedBox(height: 12 * scale),
            Divider(height: 1),
            SizedBox(height: 12 * scale),
            LayoutGrid(
              columnSizes: [auto, 1.fr],
              rowSizes: [auto],
              children: [
                Text(_getProofTypeLabel(), style: ConsciaTheme.captionStyle(context, scale).copyWith(color: ConsciaTheme.accent(context), fontWeight: FontWeight.bold)).withGridPlacement(columnStart: 0, rowStart: 0),
                Text(
                  "${_proofString.length} / $_maxProofLen chars",
                  textAlign: TextAlign.right,
                  style: ConsciaTheme.captionStyle(context, scale).copyWith(
                    fontWeight: FontWeight.bold,
                    color: _proofString.length > _maxProofLen ? ConsciaTheme.error(context) : ConsciaTheme.accent(context),
                  ),
                ).withGridPlacement(columnStart: 1, rowStart: 0),
              ],
            ),
          ],
        ),
      ),
      
      SizedBox(height: 16 * scale),
      // Limit control
      LayoutGrid(
        columnSizes: [1.fr, auto],
        rowSizes: [auto],
        children: [
          Text("Character Limit", style: ConsciaTheme.subHeadingStyle(context, scale)).withGridPlacement(columnStart: 0, rowStart: 0),
          LayoutGrid(
            columnSizes: [auto, auto, auto],
            rowSizes: [auto],
            children: [
              _limitBtn(LucideIcons.minus, _decrementLimit, scale).withGridPlacement(columnStart: 0, rowStart: 0),
              Container(
                width: 60 * scale,
                margin: EdgeInsets.symmetric(horizontal: 8 * scale),
                child: Text(
                  _maxProofLen.toString(),
                  textAlign: TextAlign.center,
                  style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold),
                ),
              ).withGridPlacement(columnStart: 1, rowStart: 0),
              _limitBtn(LucideIcons.plus, _incrementLimit, scale).withGridPlacement(columnStart: 2, rowStart: 0),
            ],
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    ],
  );

  Widget _limitBtn(IconData icon, VoidCallback onTap, double scale) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        padding: EdgeInsets.all(8 * scale),
        decoration: BoxDecoration(
          color: ConsciaTheme.surface(context),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: ConsciaTheme.border(context)),
        ),
        child: Icon(icon, size: 14 * scale, color: ConsciaTheme.accent(context)),
      ),
    );
  }

  Widget _buildStep3(double scale) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stepBadge("Step 3 of 3", "Submit URL", scale),
      SizedBox(height: 12 * scale),
      Text(
        "Paste the direct URL where you published your proof on $_selectedPlatform.",
        style: ConsciaTheme.captionStyle(context, scale),
      ),
      SizedBox(height: 20 * scale),
      TextField(
        controller: _urlController,
        style: ConsciaTheme.bodyStyle(context, scale),
        decoration: ConsciaTheme.inputDecoration(context, "https://...", scale).copyWith(
          prefixIcon: Icon(LucideIcons.link, size: 18 * scale, color: ConsciaTheme.accent(context)),
        ),
      ),
    ],
  );

  Widget _buildResult(double scale) {
    if (_verifiedSuccess) {
      return Column(children: [
        SizedBox(height: 12 * scale),
        Container(
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: Color(0xFF1B2B1B),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: Colors.green),
          ),
          child: LayoutGrid(
            columnSizes: [auto, 1.fr],
            rowSizes: [auto],
            columnGap: 16 * scale,
            children: [
              Icon(LucideIcons.checkCircle2, color: Colors.green, size: 32 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$_selectedPlatform Verified!", style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(color: Colors.green)),
                  SizedBox(height: 4 * scale),
                  Text("Your proof was found. This verification is now linked to your profile.", style: ConsciaTheme.captionStyle(context, scale)),
                ],
              ).withGridPlacement(columnStart: 1, rowStart: 0),
            ],
          ),
        ),
      ]);
    } else {
      return Column(children: [
        SizedBox(height: 12 * scale),
        Container(
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: Color(0xFF2C1616),
            borderRadius: BorderRadius.circular(16 * scale),
            border: Border.all(color: ConsciaTheme.error(context)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LayoutGrid(
              columnSizes: [auto, 1.fr],
              rowSizes: [auto],
              columnGap: 12 * scale,
              children: [
                Icon(LucideIcons.xCircle, color: ConsciaTheme.error(context), size: 32 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                Text("Proof Not Found", style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(color: ConsciaTheme.error(context))).withGridPlacement(columnStart: 1, rowStart: 0),
              ],
            ),
            SizedBox(height: 12 * scale),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : "The proof string was not found at the URL. Make sure you've published the exact proof string and try a direct/raw URL.",
              style: ConsciaTheme.captionStyle(context, scale),
            ),
          ]),
        ),
      ]);
    }
  }

  Widget _stepBadge(String step, String label, double scale) => LayoutGrid(
    columnSizes: [auto, 1.fr],
    rowSizes: [auto],
    columnGap: 10 * scale,
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
        decoration: BoxDecoration(
          color: ConsciaTheme.accentDark(context),
          borderRadius: BorderRadius.circular(20 * scale),
        ),
        child: Text(step, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: ConsciaTheme.accent(context))),
      ).withGridPlacement(columnStart: 0, rowStart: 0),
      Text(label, style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(fontSize: 16 * scale)).withGridPlacement(columnStart: 1, rowStart: 0),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(400.0, 580.0 * scale),
        ),
        clipBehavior: Clip.antiAlias,
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20 * scale),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ConsciaTheme.border(context))),
              ),
              child: LayoutGrid(
                columnSizes: [auto, 1.fr, auto],
                rowSizes: [auto],
                columnGap: 14 * scale,
                children: [
                  Icon(LucideIcons.shieldCheck, color: ConsciaTheme.accent(context), size: 24 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Verify Identity", style: ConsciaTheme.headingStyle(context, scale)),
                    Text("Cryptographic platform linking", style: ConsciaTheme.captionStyle(context, scale)),
                  ]).withGridPlacement(columnStart: 1, rowStart: 0),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(LucideIcons.x, size: 18 * scale, color: ConsciaTheme.muted(context))).withGridPlacement(columnStart: 2, rowStart: 0),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * scale),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: switch (_step) {
                    0 => _buildStep0(scale),
                    1 => _buildLoading(),
                    -1 => _buildError(scale),
                    2 => _buildStep2(scale),
                    3 => _buildStep3(scale),
                    4 => _buildResult(scale),
                    _ => SizedBox(),
                  },
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.fromLTRB(24 * scale, 0, 24 * scale, 20 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_step < 4 && _step != 1)
                    TextButton(
                      onPressed: () {
                        if (_step > 0) {
                          setState(() => _step = _step - 1);
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text((_step == 0 || _step == -1) ? "Cancel" : "Back", style: ConsciaTheme.bodyStyle(context, scale)),
                    ),
                  SizedBox(width: 12 * scale),
                  if (_step == 0 || _step == 2 || _step == 3)
                    ElevatedButton(
                      onPressed: _step == 0 ? _generateProof : (_step == 2 ? () => setState(() => _step = 3) : (_isChecking ? null : _checkProof)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ConsciaTheme.accent(context),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
                      ),
                      child: Text(_step == 0 ? "Next" : (_step == 2 ? "I've posted it" : (_isChecking ? "Checking..." : "Check Proof")), style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  if (_step == 4)
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _verifiedSuccess ? Colors.green : ConsciaTheme.accent(context),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scale)),
                      ),
                      child: Text("Done", style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final String platform;
  final bool isSelected;
  final double scale;
  final VoidCallback onTap;

  const _PlatformTile({required this.platform, required this.isSelected, required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (platform) {
      case 'GitHub': icon = LucideIcons.github; break;
      case 'Twitter/X': icon = LucideIcons.twitter; break;
      case 'Mastodon': icon = LucideIcons.globe; break;
      case 'DNS TXT': icon = LucideIcons.server; break;
      default: icon = LucideIcons.link;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? ConsciaTheme.selection(context) : ConsciaTheme.surface(context),
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: isSelected ? ConsciaTheme.accent(context) : ConsciaTheme.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? ConsciaTheme.accent(context) : ConsciaTheme.muted(context), size: 24 * scale),
            SizedBox(height: 8 * scale),
            Text(platform, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? ConsciaTheme.text(context) : ConsciaTheme.muted(context)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
