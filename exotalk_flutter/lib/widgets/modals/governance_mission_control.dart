import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../src/theme.dart';
import '../../main.dart';
import '../../providers/governance_provider.dart';

class GovernanceMissionControlModal extends ConsumerWidget {
  const GovernanceMissionControlModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('BUILDING: GovernanceMissionControlModal');
    final scale = ref.watch(uiScaleProvider);
    final govState = ref.watch(governanceProvider);
    final govNotifier = ref.read(governanceProvider.notifier);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(40.0 * scale),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.85).clamp(800.0, 1200.0 * scale),
          maxHeight: 650.0 * scale,
        ),
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: EdgeInsets.fromLTRB(32.0 * scale, 32.0 * scale, 32.0 * scale, 16.0 * scale),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: ConsciaTheme.accent(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(color: ConsciaTheme.accent(context).withValues(alpha: 0.3)),
                    ),
                    child: Icon(LucideIcons.shieldCheck, size: 24.0 * scale, color: ConsciaTheme.accent(context)),
                  ),
                  SizedBox(width: 20.0 * scale),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Governance Mission Control",
                        style: ConsciaTheme.headingStyle(context, scale),
                      ),
                      Text(
                        "Manage tier-2 join requests and network capabilities.",
                        style: ConsciaTheme.captionStyle(context, scale),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (govState.isLoading)
                    Padding(
                      padding: EdgeInsets.only(right: 16.0 * scale),
                      child: SizedBox(
                        width: 16 * scale,
                        height: 16 * scale,
                        child: CircularProgressIndicator(strokeWidth: 2 * scale, color: ConsciaTheme.accent(context)),
                      ),
                    ),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body: SYSTEMIC GRID REWRITE
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(32.0 * scale),
                child: LayoutGrid(
                  columnSizes: [1.fr, 1.fr],
                  rowSizes: [1.fr],
                  columnGap: 32.0 * scale,
                  children: [
                    // Left Column: Requests
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "JOIN REQUEST QUEUE",
                          style: ConsciaTheme.captionStyle(context, scale).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0 * scale,
                          ),
                        ),
                        SizedBox(height: 16.0 * scale),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12 * scale),
                              border: Border.all(color: ConsciaTheme.border(context)),
                            ),
                            child: govState.pendingRequests.isEmpty
                                ? Center(
                                    child: Text(
                                      "No pending requests.",
                                      style: ConsciaTheme.captionStyle(context, scale),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16 * scale),
                                    itemCount: govState.pendingRequests.length,
                                    separatorBuilder: (_, index) => Divider(color: ConsciaTheme.border(context)),
                                    itemBuilder: (context, index) {
                                      final id = govState.pendingRequests[index];
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8 * scale),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "${id.substring(0, 12)}...",
                                                style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace'),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                _ActionButton(
                                                  label: "User",
                                                  isPrimary: true,
                                                  scale: scale,
                                                  onTap: () => govNotifier.authorizeNode(id, "User"),
                                                ),
                                                SizedBox(width: 8 * scale),
                                                _ActionButton(
                                                  label: "Delegate",
                                                  isPrimary: false,
                                                  scale: scale,
                                                  onTap: () => govNotifier.authorizeNode(id, "Delegate"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ).withGridPlacement(columnStart: 0, rowStart: 0),
                    
                    // Right Column: Roles
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NETWORK ROLES & REGISTRY",
                          style: ConsciaTheme.captionStyle(context, scale).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0 * scale,
                          ),
                        ),
                        SizedBox(height: 16.0 * scale),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12 * scale),
                              border: Border.all(color: ConsciaTheme.border(context)),
                            ),
                            child: govState.activeRoles.isEmpty
                                ? Center(
                                    child: Text(
                                      "No registered roles.",
                                      style: ConsciaTheme.captionStyle(context, scale),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(16 * scale),
                                    itemCount: govState.activeRoles.length,
                                    separatorBuilder: (_, index) => Divider(color: ConsciaTheme.border(context)),
                                    itemBuilder: (context, index) {
                                      final entry = govState.activeRoles.entries.elementAt(index);
                                      return Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8 * scale),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${entry.key.substring(0, 16)}...",
                                              style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace'),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                                              decoration: BoxDecoration(
                                                color: ConsciaTheme.accent(context).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(4 * scale),
                                                border: Border.all(color: ConsciaTheme.accent(context).withValues(alpha: 0.3)),
                                              ),
                                              child: Text(
                                                entry.value.toUpperCase(),
                                                style: TextStyle(
                                                  color: ConsciaTheme.accent(context),
                                                  fontSize: 10 * scale,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ).withGridPlacement(columnStart: 1, rowStart: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final double scale;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.isPrimary, required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: isPrimary ? ConsciaTheme.accent(context) : Colors.transparent,
          border: Border.all(color: ConsciaTheme.accent(context)),
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : ConsciaTheme.accent(context),
            fontSize: 11 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
