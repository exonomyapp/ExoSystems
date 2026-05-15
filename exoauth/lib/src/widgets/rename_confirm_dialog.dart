// =============================================================================
// rename_confirm_dialog.dart — Rename Identity
// =============================================================================
//
// Renaming an identity is not a trivial action. Unlike
// systems where a username change is atomic, a did:peer rename
// triggers side-effects:
//
//   1. **History Archival** — The previous name becomes a NameRecord with
//      its own proof string and timestamp, preserved for auditability.
//
//   2. **Verified Link Invalidation** — All platform links that were verified
//      under the old name are moved to the archive. The user must re-verify
//      them under the new name to maintain their trust graph.
//
//   3. **Change Certificate Broadcast** — A signed certificate is gossiped
//      to peers announcing the rename, so they can update their contact
//      books and display "NewName (formerly OldName)".
//
// This dialog ensures the user understands these consequences before
// committing. It is a "Pure UI" component — all state mutation happens
// via IdentityService after the user confirms.
//
// See: docs/spec/02_identity_and_access.md §2.3 for the rename protocol.
// =============================================================================

import '../theme.dart';
import '../providers.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

class RenameConfirmDialog extends ConsumerWidget {
  final String oldName;
  final String newName;
  final int verifiedLinksCount;

  const RenameConfirmDialog({
    super.key,
    required this.oldName,
    required this.newName,
    required this.verifiedLinksCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(400.0, 480.0 * scale),
        ),
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24.0 * scale),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: ConsciaTheme.border(context))),
              ),
              child: LayoutGrid(
                columnSizes: [auto, 1.fr],
                rowSizes: [auto],
                columnGap: 16.0 * scale,
                children: [
                  Icon(LucideIcons.alertCircle, color: ConsciaTheme.accent(context), size: 24.0 * scale).withGridPlacement(columnStart: 0, rowStart: 0),
                  Text("Rename Identity?", style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(fontWeight: FontWeight.bold)).withGridPlacement(columnStart: 1, rowStart: 0),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(24.0 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: ConsciaTheme.bodyStyle(context, scale).copyWith(height: 1.5, fontSize: 13.0 * scale),
                      children: [
                        TextSpan(text: "You are renaming "),
                        TextSpan(text: oldName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        TextSpan(text: " to "),
                        TextSpan(text: newName, style: TextStyle(fontWeight: FontWeight.bold, color: ConsciaTheme.accent(context))),
                        TextSpan(text: "."),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.0 * scale),
                  _buildImpactItem(
                    context,
                    LucideIcons.history,
                    "Your history as '$oldName' will be archived.",
                    scale,
                  ),
                  if (verifiedLinksCount > 0)
                    _buildImpactItem(
                      context,
                      LucideIcons.shieldOff,
                      "Your $verifiedLinksCount verified links will be moved to history.",
                      scale,
                    ),
                  _buildImpactItem(
                    context,
                    LucideIcons.radio,
                    "A signed change certificate will be broadcast to peers.",
                    scale,
                  ),
                  _buildImpactItem(
                    context,
                    LucideIcons.users,
                    "Peers will see '$newName (formerly $oldName)'.",
                    scale,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(24.0 * scale),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ConsciaTheme.border(context))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Cancel", style: ConsciaTheme.bodyStyle(context, scale).copyWith(color: ConsciaTheme.muted(context))),
                  ),
                  SizedBox(width: 12.0 * scale),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConsciaTheme.accent(context),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.0 * scale, vertical: 12.0 * scale),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
                    ),
                    child: Text("Confirm Rename", style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(BuildContext context, IconData icon, String text, double scale) => Padding(
    padding: EdgeInsets.only(bottom: 12.0 * scale),
    child: LayoutGrid(
      columnSizes: [auto, 1.fr],
      rowSizes: [auto],
      columnGap: 12.0 * scale,
      children: [
        Icon(icon, size: 16.0 * scale, color: ConsciaTheme.muted(context)).withGridPlacement(columnStart: 0, rowStart: 0),
        Text(
          text,
          style: ConsciaTheme.captionStyle(context, scale),
        ).withGridPlacement(columnStart: 1, rowStart: 0),
      ],
    ),
  );
}
