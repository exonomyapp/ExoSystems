import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../../src/theme.dart';
import '../../providers/conscia_provider.dart';
import '../../main.dart';
import '../../src/rust/api/network.dart';
import '../../providers/governance_provider.dart';
import '../../providers/chat_provider.dart';
import 'home_screen.dart';
import '../widgets/pulsing_icon.dart';

/// A full-page view that displays detailed telemetry and management controls for an associated Conscia node.
/// It consumes state from multiple providers to synthesize a unified dashboard for status, networking, and security.
class NodeManagementView extends ConsumerWidget {
  const NodeManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double scale = ref.watch(uiScaleProvider);
    final selectedNodeId = ref.watch(selectedNodeIdProvider);
    final peersAsync = ref.watch(peerListProvider);

    final selectedPeer = peersAsync.whenData(
      (peers) => peers.cast<PeerInfo?>().firstWhere(
        (p) => p?.nodeId == selectedNodeId,
        orElse: () => null,
      ),
    ).valueOrNull;

    return Container(
      color: ConsciaTheme.background(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedPeer == null)
             _NotificationBanner(
               scale: scale, 
               message: "No node selected. Choose a Conscia node from the sidebar.",
               type: NotificationType.info,
             ),
          _NodeHeader(scale: scale, peer: selectedPeer),
          Expanded(
            child: selectedPeer == null
                ? _EmptySelection(scale: scale)
                : CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(ConsciaTheme.cardPadding(scale)),
                        sliver: SliverToBoxAdapter(
                          child: _DashboardGrid(scale: scale, selectedPeer: selectedPeer),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final double scale;
  final PeerInfo selectedPeer;
  const _DashboardGrid({required this.scale, required this.selectedPeer});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width < 850) {
          // Mobile: 1-column stack
          return LayoutGrid(
            gridFit: GridFit.expand,
            columnSizes: [1.fr],
            rowSizes: const [auto, auto, auto, auto],
            rowGap: ConsciaTheme.elementSpacing(scale),
            columnGap: ConsciaTheme.elementSpacing(scale),
            children: [
              _HealthTelemetry(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, rowStart: 0),
              _OperationalPulse(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, rowStart: 1),
              _CapabilityCard(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, rowStart: 2),
              _AdvancedSettings(scale: scale).withGridPlacement(columnStart: 0, rowStart: 3),
            ],
          );
        } else if (width < 1350) {
          // Tablet: 2-row grid (Health/Pulse, then Capabilities)
          return LayoutGrid(
            gridFit: GridFit.expand,
            columnSizes: [1.fr, 1.fr],
            rowSizes: const [auto, auto, auto],
            rowGap: ConsciaTheme.elementSpacing(scale),
            columnGap: ConsciaTheme.elementSpacing(scale),
            children: [
              _HealthTelemetry(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, rowStart: 0),
              _OperationalPulse(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 1, rowStart: 0),
              _CapabilityCard(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, columnSpan: 2, rowStart: 1),
              _AdvancedSettings(scale: scale).withGridPlacement(columnStart: 0, columnSpan: 2, rowStart: 2),
            ],
          );
        } else {
          // Desktop: 5-4-2 Grid
          return LayoutGrid(
            gridFit: GridFit.expand,
            columnSizes: [5.fr, 4.fr, 2.fr],
            rowSizes: const [
              auto, // Metrics Row
              auto, // Config Row
            ],
            rowGap: ConsciaTheme.elementSpacing(scale),
            columnGap: ConsciaTheme.elementSpacing(scale),
            children: [
              _HealthTelemetry(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 0, rowStart: 0),
              _OperationalPulse(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 1, rowStart: 0),
              _CapabilityCard(scale: scale, peer: selectedPeer).withGridPlacement(columnStart: 2, rowStart: 0),
              _AdvancedSettings(scale: scale).withGridPlacement(columnStart: 0, columnSpan: 3, rowStart: 1),
            ],
          );
        }
      },
    );
  }
}

enum NotificationType { info, warning, error }

class _NotificationBanner extends StatelessWidget {
  final double scale;
  final String message;
  final NotificationType type;

  const _NotificationBanner({required this.scale, required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = type == NotificationType.error 
        ? ConsciaTheme.dangerBg(context)
        : (type == NotificationType.warning ? ConsciaTheme.warningBg(context) : ConsciaTheme.accentBg(context));
    
    final Color textColor = type == NotificationType.error 
        ? ConsciaTheme.error(context)
        : (type == NotificationType.warning ? ConsciaTheme.warning(context) : ConsciaTheme.accent(context));

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ConsciaTheme.headerPaddingHorizontal(scale), vertical: 12.0 * scale),
      color: bgColor,
      child: Row(
        children: [
          Icon(
            type == NotificationType.error ? LucideIcons.alertCircle : (type == NotificationType.warning ? LucideIcons.alertTriangle : LucideIcons.info),
            size: 16.0 * scale,
            color: textColor,
          ),
          SizedBox(width: 12.0 * scale),
          Expanded(
            child: Text(
              message,
              style: ConsciaTheme.captionStyle(context, scale).copyWith(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  final double scale;
  const _EmptySelection({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.server, size: 48.0 * scale, color: ConsciaTheme.border(context)),
          SizedBox(height: 16.0 * scale),
          Text("No node selected.", style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(color: ConsciaTheme.muted(context))),
          SizedBox(height: 8.0 * scale),
          Text("Choose a Conscia node from the sidebar to view its details.", style: ConsciaTheme.captionStyle(context, scale)),
        ],
      ),
    );
  }
}

/// Unified header providing node identity and a high-level health impression.
class _NodeHeader extends ConsumerWidget {
  final double scale;
  final PeerInfo? peer;
  const _NodeHeader({required this.scale, required this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(consciaStatusProvider);
    final isConnected = statusAsync.whenData((s) => s.nodeId == peer?.nodeId && s.isConnected).valueOrNull ?? false;

    final isAsleep = ref.watch(nodeSleepProvider);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ConsciaTheme.headerPaddingHorizontal(scale), 
        vertical: ConsciaTheme.headerPaddingVertical(scale) * 0.75,
      ),
      decoration: BoxDecoration(
        color: ConsciaTheme.surfaceElevated(context),
        border: Border(bottom: BorderSide(color: ConsciaTheme.border(context))),
      ),
      child: Row(
        children: [
          ConsciaHeaderIcon(
            isSleeping: isAsleep,
            scale: scale,
            onTap: () => ref.read(nodeSleepProvider.notifier).state = !isAsleep,
          ),
          SizedBox(width: 20.0 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text("Conscia Node", style: ConsciaTheme.headingStyle(context, scale), overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 8.0 * scale),
                    if (peer != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.0 * scale, vertical: 2.0 * scale),
                        decoration: BoxDecoration(
                          color: isConnected ? ConsciaTheme.accentBg(context) : ConsciaTheme.dangerBg(context),
                          borderRadius: BorderRadius.circular(4.0 * scale),
                        ),
                        child: Text(
                          isConnected ? "ONLINE" : "UNREACHABLE",
                          style: TextStyle(
                            fontSize: 10.0 * scale,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? ConsciaTheme.accent(context) : ConsciaTheme.error(context),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.0 * scale),
                Text(
                  peer?.nodeId ?? "Select a node to begin governance.",
                  style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: peer != null ? 'monospace' : null),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Actions: Sleep and Return Home
          Row(
            children: [
              Consumer(builder: (context, ref, _) {
                final isAsleep = ref.watch(nodeSleepProvider);
                return IconButton(
                  icon: Icon(isAsleep ? LucideIcons.moon : LucideIcons.sun, size: 20 * scale, color: isAsleep ? ConsciaTheme.warning(context) : ConsciaTheme.accent(context)),
                  tooltip: isAsleep ? "Wake Node" : "Sleep Node",
                  onPressed: () => ref.read(nodeSleepProvider.notifier).state = !isAsleep,
                );
              }),
              SizedBox(width: 12 * scale),
              IconButton(
                icon: Icon(LucideIcons.home, size: 20 * scale, color: ConsciaTheme.muted(context)),
                tooltip: "Return Home",
                onPressed: () {
                  ref.read(activeMainViewProvider.notifier).state = MainView.chat;
                  ref.read(activeConversationIdProvider.notifier).set(null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthTelemetry extends StatelessWidget {
  final double scale;
  final PeerInfo peer;
  const _HealthTelemetry({required this.scale, required this.peer});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final statusAsync = ref.watch(consciaStatusProvider);
      final isAsleep = ref.watch(nodeSleepProvider);
      final status = statusAsync.valueOrNull;
      final peerCount = isAsleep ? 0 : (status?.activePeers ?? peer.addresses.length);
      final latency = "--"; // Removing hardcoded simulation
      const storage = "--"; 
      
      return _DashboardCard(
        scale: scale,
        title: "Health Dashboard",
        icon: LucideIcons.activity,
        headerTrailing: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InlineMetric(scale: scale, label: "PEERS", value: "$peerCount", icon: LucideIcons.users),
              SizedBox(width: 16.0 * scale),
              _InlineMetric(scale: scale, label: "LATENCY", value: latency, icon: LucideIcons.timer),
              SizedBox(width: 16.0 * scale),
              _InlineMetric(scale: scale, label: "STORAGE", value: storage, icon: LucideIcons.database),
            ],
          ),
        ),
        fillHeight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (peer.addresses.isNotEmpty) ...[
              SizedBox(height: 16.0 * scale),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.0 * scale),
                  decoration: BoxDecoration(
                    color: ConsciaTheme.background(context),
                    borderRadius: BorderRadius.circular(12.0 * scale),
                    border: Border.all(color: ConsciaTheme.border(context)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PEER ADDRESSES", style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8.0 * scale),
                        ...peer.addresses.map((addr) {
                          final isIPv6 = addr.startsWith('[');
                          final isDerp = addr.contains('derp');
                          final typeStr = isDerp ? 'RELAY' : (isIPv6 ? 'IPv6' : 'IPv4');
                          final badgeBg = isDerp ? ConsciaTheme.warningBg(context) : ConsciaTheme.accentBg(context);
                          final badgeFg = isDerp ? ConsciaTheme.warning(context) : ConsciaTheme.accent(context);
                          
                          return Padding(
                            padding: EdgeInsets.only(bottom: 6.0 * scale),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0 * scale, vertical: 2.0 * scale),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(4.0 * scale),
                                  ),
                                  child: Text(typeStr, style: TextStyle(fontSize: 8.0 * scale, fontWeight: FontWeight.bold, color: badgeFg)),
                                ),
                                SizedBox(width: 8.0 * scale),
                                Expanded(
                                  child: Text(addr, style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace')),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _InlineMetric extends StatelessWidget {
  final double scale;
  final String label;
  final String value;
  final IconData icon;

  const _InlineMetric({required this.scale, required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.0 * scale, color: ConsciaTheme.muted(context)),
            SizedBox(width: 4.0 * scale),
            Text(value, style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9.0 * scale, color: ConsciaTheme.muted(context), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }
}

/// Live operational telemetry. Admins see activity logs; non-admins see a health pulse.
class _OperationalPulse extends ConsumerWidget {
  final double scale;
  final PeerInfo peer;
  const _OperationalPulse({required this.scale, required this.peer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final governance = ref.watch(governanceProvider);
    final hasAdmin = governance.activeRoles[peer.nodeId]?.toLowerCase() == 'admin';

    return _DashboardCard(
      scale: scale,
      title: "Operational Pulse",
      icon: LucideIcons.terminal,
      fillHeight: true,
      // Systemic Fix: Remove internal padding for the terminal feed to create "Terminal Abundance"
      contentPadding: hasAdmin ? EdgeInsets.zero : null, 
      child: hasAdmin ? _AdminTelemetry(scale: scale) : _UserHeartbeat(scale: scale),
    );
  }
}

class _AdminTelemetry extends ConsumerWidget {
  final double scale;
  const _AdminTelemetry({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(nodeActivityProvider);

    // Systemic Fix: Use a pure terminal look that fills the card frame edge-to-edge.
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: ConsciaTheme.background(context).withValues(alpha: 0.5),
      padding: EdgeInsets.all(12.0 * scale),
      child: activityAsync.when(
        data: (logs) => ListView.builder(
          itemCount: logs.length,
          itemBuilder: (ctx, i) => Padding(
            padding: EdgeInsets.only(bottom: 4.0 * scale),
            child: Text(
              logs[i],
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11.0 * scale,
                color: ConsciaTheme.accent(context),
                height: 1.2,
              ),
            ),
          ),
        ),
        loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2, color: ConsciaTheme.accent(context))),
        error: (err, _) => Center(child: Text("Telemetry Error: $err", style: ConsciaTheme.captionStyle(context, scale))),
      ),
    );
  }
}

class _UserHeartbeat extends StatelessWidget {
  final double scale;
  const _UserHeartbeat({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final isAsleep = ref.watch(nodeSleepProvider);
      final isConnected = ref.watch(consciaStatusProvider).value?.isConnected ?? false;
      
      return Row(
        children: [
          Icon(
            !isConnected ? LucideIcons.unplug : (isAsleep ? LucideIcons.moon : LucideIcons.heartPulse), 
            size: 20.0 * scale, 
            color: !isConnected ? ConsciaTheme.error(context) : (isAsleep ? ConsciaTheme.warning(context) : ConsciaTheme.accent(context))
          ),
          SizedBox(width: 16.0 * scale),
          // Systemic Fix: Wrap text in Expanded to prevent the "Yellow Stripe" overflow on small resolutions.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  !isConnected ? "Connection Lost" : (isAsleep ? "System Standby" : "System Optimal"), 
                  style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold)
                ),
                Text(
                  !isConnected 
                    ? "Remote node is unreachable. Check power and network."
                    : (isAsleep 
                        ? "Node is in low-power standby mode. Mesh processing paused." 
                        : "Node is processing mesh traffic normally."), 
                  style: ConsciaTheme.captionStyle(context, scale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _AdvancedSettings extends StatelessWidget {
  final double scale;
  const _AdvancedSettings({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      scale: scale,
      title: "Advanced Configuration",
      icon: LucideIcons.settings2,
      fillHeight: false, // Don't expand in a ListView!
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Privileged settings for HA clusters and Conscierge AI tuning will appear here when authorized.",
            style: ConsciaTheme.captionStyle(context, scale),
          ),
          SizedBox(height: 16.0 * scale),
          Opacity(
            opacity: 0.3,
            child: Row(
              children: [
                _GhostButton(scale: scale, label: "Manage Cluster"),
                SizedBox(width: 12.0 * scale),
                _GhostButton(scale: scale, label: "AI Concierge"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final double scale;
  final String label;
  const _GhostButton({required this.scale, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 8.0 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: ConsciaTheme.border(context)),
        borderRadius: BorderRadius.circular(8.0 * scale),
      ),
      child: Text(label, style: TextStyle(fontSize: 12.0 * scale, fontWeight: FontWeight.bold)),
    );
  }
}

/// Manages and displays Meadowcap capability delegations for the selected node.
class _CapabilityCard extends ConsumerStatefulWidget {
  final double scale;
  final PeerInfo peer;
  const _CapabilityCard({required this.scale, required this.peer});

  @override
  ConsumerState<_CapabilityCard> createState() => _CapabilityCardState();
}

class _CapabilityCardState extends ConsumerState<_CapabilityCard> {
  String _selectedRole = 'Write';

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final peer = widget.peer;
    final governance = ref.watch(governanceProvider);
    final role = governance.activeRoles[peer.nodeId];
    final hasCap = role != null;

    return _DashboardCard(
      scale: scale,
      title: "Capabilities",
      icon: LucideIcons.shieldCheck,
      fillHeight: true,
      child: governance.isLoading
          ? Center(child: SizedBox(width: 16.0 * scale, height: 16.0 * scale, child: CircularProgressIndicator(strokeWidth: 2, color: ConsciaTheme.accent(context))))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCap)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 8.0 * scale),
                    margin: EdgeInsets.only(bottom: 16.0 * scale),
                    decoration: BoxDecoration(
                      color: ConsciaTheme.accentDark(context),
                      borderRadius: BorderRadius.circular(8.0 * scale),
                      border: Border.all(color: ConsciaTheme.accent(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 14.0 * scale, color: ConsciaTheme.accent(context)),
                        SizedBox(width: 8.0 * scale),
                        Expanded(
                          child: Text(
                            role.toUpperCase(),
                            style: ConsciaTheme.captionStyle(context, scale).copyWith(
                              color: ConsciaTheme.accent(context),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  "Grant Role",
                  style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: ConsciaTheme.text(context)),
                ),
                SizedBox(height: 8.0 * scale),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 320.0 * scale),
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0 * scale),
                        decoration: BoxDecoration(
                          color: ConsciaTheme.background(context),
                          borderRadius: BorderRadius.circular(8.0 * scale),
                          border: Border.all(color: ConsciaTheme.border(context)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            dropdownColor: ConsciaTheme.surfaceElevated(context),
                            icon: Icon(LucideIcons.chevronDown, size: 14.0 * scale, color: ConsciaTheme.muted(context)),
                            style: ConsciaTheme.captionStyle(context, scale),
                            onChanged: (String? newValue) {
                              if (newValue != null) setState(() => _selectedRole = newValue);
                            },
                            items: <String>['Admin', 'Write', 'Read']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.0 * scale),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 320.0 * scale),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ConsciaTheme.accent(context),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0 * scale)),
                        ),
                          onPressed: governance.isLoading ? null : () {
                            ref.read(governanceProvider.notifier).authorizeNode(peer.nodeId, _selectedRole);
                          },
                        icon: Icon(LucideIcons.shieldCheck, size: 14.0 * scale),
                        label: Text(hasCap ? "Re-authorize" : "Grant", style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                if (hasCap) ...[
                  SizedBox(height: 8.0 * scale),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 320.0 * scale),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ConsciaTheme.dangerBorder(context)),
                            foregroundColor: ConsciaTheme.error(context),
                            padding: EdgeInsets.symmetric(vertical: 12.0 * scale),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0 * scale)),
                          ),
                            onPressed: governance.isLoading ? null : () {
                                ref.read(governanceProvider.notifier).revokeNode(peer.nodeId);
                            },
                          icon: Icon(LucideIcons.shieldOff, size: 14.0 * scale),
                          label: Text("Revoke Role", style: ConsciaTheme.captionStyle(context, scale).copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Formalized dashboard card component that adheres to ConsciaTheme standards.
class _DashboardCard extends StatelessWidget {
  final double scale;
  final String title;
  final IconData icon;
  final Widget child;
  final bool fillHeight;
  final EdgeInsets? contentPadding;
  final Widget? headerTrailing;

  const _DashboardCard({
    required this.scale, 
    required this.title, 
    required this.icon, 
    required this.child, 
    this.fillHeight = false,
    this.contentPadding,
    this.headerTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ConsciaTheme.surface(context),
        borderRadius: BorderRadius.circular(16.0 * scale),
        border: Border.all(color: ConsciaTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (always padded)
          Padding(
            padding: EdgeInsets.all(ConsciaTheme.cardPadding(scale)).copyWith(bottom: 0),
            child: Row(
              children: [
                Icon(icon, size: 16.0 * scale, color: ConsciaTheme.accent(context)),
                SizedBox(width: 10.0 * scale),
                Expanded(
                  child: Text(
                    title, 
                    style: ConsciaTheme.subHeadingStyle(context, scale),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (headerTrailing != null) ...[
                  SizedBox(width: 12.0 * scale),
                  headerTrailing!,
                ],
              ],
            ),
          ),
          SizedBox(height: ConsciaTheme.elementSpacing(scale)),
          // Body (supports edge-to-edge)
          if (fillHeight)
            Expanded(
              child: Padding(
                padding: contentPadding ?? EdgeInsets.symmetric(horizontal: ConsciaTheme.cardPadding(scale)).copyWith(bottom: ConsciaTheme.cardPadding(scale)),
                child: child,
              ),
            )
          else
            Padding(
              padding: contentPadding ?? EdgeInsets.symmetric(horizontal: ConsciaTheme.cardPadding(scale)).copyWith(bottom: ConsciaTheme.cardPadding(scale)),
              child: child,
            ),
        ],
      ),
    );
  }
}
