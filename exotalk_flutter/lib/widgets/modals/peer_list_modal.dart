import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../../src/theme.dart';
import '../../main.dart';
import '../../providers/peer_provider.dart';
import '../../src/rust/api/network.dart';

class PeerListModal extends ConsumerWidget {
  const PeerListModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final peersAsync = ref.watch(peerListProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(40.0 * scale),
      child: Container(
        width: (MediaQuery.of(context).size.width * 0.95).clamp(600.0, 1200.0 * scale),
        height: (MediaQuery.of(context).size.height * 0.85).clamp(500.0, 800.0 * scale),
        decoration: ConsciaTheme.premiumCardDecoration(context, scale),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: EdgeInsets.fromLTRB(32.0 * scale, 32.0 * scale, 32.0 * scale, 16.0 * scale),
              child: LayoutGrid(
                columnSizes: [auto, 1.fr, auto, auto],
                rowSizes: [auto],
                columnGap: 20.0 * scale,
                children: [
                  Container(
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: ConsciaTheme.accent(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12 * scale),
                      border: Border.all(color: ConsciaTheme.accent(context).withValues(alpha: 0.3)),
                    ),
                    child: Icon(LucideIcons.network, size: 24.0 * scale, color: ConsciaTheme.accent(context)),
                  ).withGridPlacement(columnStart: 0, rowStart: 0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Active Mesh Roster",
                        style: ConsciaTheme.headingStyle(context, scale).copyWith(fontSize: 22.0 * scale),
                      ),
                      Text(
                        "Real-time visibility into cryptographic peers and network entry points.",
                        style: ConsciaTheme.captionStyle(context, scale),
                      ),
                    ],
                  ).withGridPlacement(columnStart: 1, rowStart: 0),
                  _PeerCountBadge(scale: scale).withGridPlacement(columnStart: 2, rowStart: 0),
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 20.0 * scale, color: ConsciaTheme.muted(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ).withGridPlacement(columnStart: 3, rowStart: 0),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: peersAsync.when(
                data: (peers) {
                  if (peers.isEmpty) {
                    return _EmptyState(scale: scale);
                  }

                  return GridView.builder(
                    padding: EdgeInsets.all(32 * scale),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400 * scale,
                      mainAxisExtent: 220 * scale,
                      crossAxisSpacing: 24 * scale,
                      mainAxisSpacing: 24 * scale,
                    ),
                    itemCount: peers.length,
                    itemBuilder: (context, index) {
                      return _PeerCard(peer: peers[index], scale: scale);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err", style: TextStyle(color: ConsciaTheme.error(context)))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerCountBadge extends ConsumerWidget {
  final double scale;
  const _PeerCountBadge({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peersAsync = ref.watch(peerListProvider);
    final count = peersAsync.when(data: (p) => p.length, loading: () => 0, error: (_, _) => 0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: ConsciaTheme.background(context),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: ConsciaTheme.border(context)),
      ),
      child: LayoutGrid(
        columnSizes: [auto, auto],
        rowSizes: [auto],
        columnGap: 8 * scale,
        children: [
          Container(
            width: 6 * scale,
            height: 6 * scale,
            decoration: BoxDecoration(color: ConsciaTheme.accent(context), shape: BoxShape.circle),
          ).withGridPlacement(columnStart: 0, rowStart: 0),
          Text(
            "$count PEERS ACTIVE",
            style: ConsciaTheme.bodyStyle(context, scale).copyWith(
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5 * scale,
              color: ConsciaTheme.accent(context),
            ),
          ).withGridPlacement(columnStart: 1, rowStart: 0),
        ],
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  final PeerInfo peer;
  final double scale;

  const _PeerCard({required this.peer, required this.scale});

  @override
  Widget build(BuildContext context) {
    final knownNodes = {
      "2f4300ae2c116d3c0f87cea35cc0254900a217558878d55010e435e30b0cc9b4": ("Exocracy (Host)", "Nexus Beacon", LucideIcons.castle),
      "83fa401028e4f8b8cf9ad85801fb27b8905faffec13ee22caa2a1a9b09c052e1": ("Exonomy (Node)", "Federated Node", LucideIcons.satellite),
      "613e962785bff825e9bb522428a78f457195b3fc7d327f694c662bbcb541eb87": ("ExoTalk (Flutter)", "Sovereign App", LucideIcons.smartphone),
    };

    final nodeInfo = knownNodes[peer.nodeId] ?? ("Unknown Peer", "Anonymous Node", LucideIcons.helpCircle);
    
    final hasLocal = peer.addresses.any((a) => a.startsWith('10.') || a.startsWith('192.168.') || a.startsWith('172.'));
    final hasRelay = peer.addresses.any((a) => a.contains('relay.iroh.network'));
    final hasDirect = peer.addresses.any((a) => !a.contains('relay') && !a.startsWith('10.') && !a.startsWith('192.168.') && !a.startsWith('172.'));

    return Container(
      decoration: BoxDecoration(
        color: ConsciaTheme.surface(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: ConsciaTheme.border(context)),
      ),
      padding: EdgeInsets.all(20 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutGrid(
            columnSizes: [auto, 1.fr, auto],
            rowSizes: [auto],
            columnGap: 16 * scale,
            children: [
              Container(
                width: 44 * scale,
                height: 44 * scale,
                decoration: BoxDecoration(
                  color: ConsciaTheme.background(context),
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(color: ConsciaTheme.border(context)),
                ),
                child: Icon(nodeInfo.$3, size: 20 * scale, color: ConsciaTheme.accent(context)),
              ).withGridPlacement(columnStart: 0, rowStart: 0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nodeInfo.$1,
                    style: ConsciaTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold, fontSize: 15 * scale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${peer.nodeId.substring(0, 8)}...${peer.nodeId.substring(peer.nodeId.length - 8)}",
                    style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace', fontSize: 10 * scale),
                  ),
                ],
              ).withGridPlacement(columnStart: 1, rowStart: 0),
              _StatusIndicator(scale: scale).withGridPlacement(columnStart: 2, rowStart: 0),
            ],
          ),
          SizedBox(height: 16 * scale),
          Wrap(
            spacing: 6 * scale,
            runSpacing: 6 * scale,
            children: [
              _Badge(label: nodeInfo.$2, color: ConsciaTheme.accent(context), scale: scale),
              if (hasLocal) _Badge(label: "LOCAL", color: Colors.blue, scale: scale),
              if (hasDirect) _Badge(label: "DIRECT", color: Colors.orange, scale: scale),
              if (hasRelay) _Badge(label: "RELAY", color: ConsciaTheme.muted(context), scale: scale),
            ],
          ),
          SizedBox(height: 16 * scale),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(color: ConsciaTheme.border(context).withValues(alpha: 0.5)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: peer.addresses.map((addr) => Padding(
                    padding: EdgeInsets.only(bottom: 2 * scale),
                    child: Text(
                      "• $addr",
                      style: ConsciaTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace', fontSize: 9 * scale),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final double scale;
  const _StatusIndicator({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8 * scale,
      height: 8 * scale,
      decoration: BoxDecoration(
        color: ConsciaTheme.accent(context),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: ConsciaTheme.accent(context).withValues(alpha: 0.5), blurRadius: 4 * scale, spreadRadius: 2 * scale),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final double scale;

  const _Badge({required this.label, required this.color, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5 * scale,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double scale;
  const _EmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, size: 48 * scale, color: ConsciaTheme.muted(context).withValues(alpha: 0.3)),
          SizedBox(height: 24 * scale),
          Text(
            "No active peers found in mesh",
            style: ConsciaTheme.headingStyle(context, scale).copyWith(fontSize: 18 * scale, color: ConsciaTheme.muted(context)),
          ),
          SizedBox(height: 8 * scale),
          Text(
            "Looking for beacons and federated nodes...",
            style: ConsciaTheme.captionStyle(context, scale),
          ),
        ],
      ),
    );
  }
}
