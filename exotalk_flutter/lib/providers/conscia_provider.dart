// =============================================================================
// conscia_provider.dart — Conscia "Lifeline" Connection Monitor
// =============================================================================
//
// Conscia nodes are always-on Iroh peers that provide data persistence
// ("Lifeline") for the user's Willow replica when their devices are offline.
// Think of them as a personal cloud mirror — they don't own your data, but
// they keep a synchronized copy available for your other devices.
//
// This provider polls the Rust engine every 500ms to check whether the
// associated Conscia node is reachable. The status is displayed in the
// sidebar footer via `_ConsciaStatusFooter` in home_screen.dart.
//
// See: docs/spec/10_identity_vault.md §10.2 for the persistence model.
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';
import '../src/rust/api/network.dart';
import '../src/rust/api/willow.dart';

/// Provider that periodically polls the Rust engine for the Conscia connection status.
final consciaStatusProvider = StreamProvider<ConsciaStatus>((ref) async* {
  // Watch identity to trigger a provider restart on every sign-in/switch
  final identity = ref.watch(identityProvider);
  
  // If no one is signed in, we are disconnected by definition
  if (identity.activeDid == null) {
    yield const ConsciaStatus(nodeId: null, isConnected: false, activePeers: 0);
    return;
  }

  // Grace Period: 500ms to allow for initial handshake.
  yield const ConsciaStatus(nodeId: null, isConnected: false, activePeers: 0);
  await Future.delayed(const Duration(milliseconds: 500));

  // Yield the initial status with the engine's liveness check
  final rawInitial = await getConsciaStatus();
  
  final initial = ConsciaStatus(
    nodeId: rawInitial.nodeId,
    isConnected: rawInitial.isConnected,
    activePeers: rawInitial.activePeers,
  );
  debugPrint("DEBUG: Conscia Status Initial: connected=${initial.isConnected} (raw=${rawInitial.isConnected}, activePeers=${initial.activePeers})");
  yield initial;

  // Then poll every 500ms
  while (true) {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final rawStatus = await getConsciaStatus();

      final status = ConsciaStatus(
        nodeId: rawStatus.nodeId,
        isConnected: rawStatus.isConnected,
        activePeers: rawStatus.activePeers, 
      );
      yield status;
    } catch (e) {
      debugPrint("DEBUG: Conscia Status Poll Error: $e");
      // If the engine is busy or restarting, just yield an offline status
      yield const ConsciaStatus(nodeId: null, isConnected: false, activePeers: 0);
    }
  }
});

/// Notifier to manage the associated Conscia ID (e.g. from an invitation)
class AssociatedConsciaNotifier extends Notifier<String?> {
  @override
  String? build() {
    // We load the initial state asynchronously
    _loadFromManifest();
    return null;
  }

  Future<void> _loadFromManifest() async {
    try {
      final manifest = await getDeviceManifest();
      state = manifest.associatedConsciaId;
    } catch (_) {}
  }

  Future<void> associateNode(String nodeId) async {
    await setAssociatedConscia(nodeId: nodeId);
    state = nodeId;
  }
}

final associatedConsciaProvider = NotifierProvider<AssociatedConsciaNotifier, String?>(() {
  return AssociatedConsciaNotifier();
});

/// Exposes the live roster of associated Conscia peers from the Rust engine.
/// Polls every 500ms to detect newly-discovered mesh peers.
/// Invalidate this provider after manually adding a node to trigger an immediate refresh.
final peerListProvider = StreamProvider<List<PeerInfo>>((ref) async* {
  final identity = ref.watch(identityProvider);
  if (identity.activeDid == null) {
    yield [];
    return;
  }

  // Same grace period for peer discovery
  yield [];
  await Future.delayed(const Duration(milliseconds: 500));

  final initial = await getPeerList();
  final initialIds = initial.map((p) => "${p.nodeId.substring(0, 8)}(${p.addresses.length} addrs)").join(", ");
  debugPrint("DEBUG: Peer List Initial: count=${initial.length} (IDs: [$initialIds])");
  yield initial;

  while (true) {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final list = await getPeerList();
      if (list.length != initial.length) {
        final ids = list.map((p) => "${p.nodeId.substring(0, 8)}(${p.addresses.length} addrs)").join(", ");
        debugPrint("DEBUG: Peer List Update: count=${list.length} (IDs: [$ids])");
      }
      yield list;
    } catch (e) {
      debugPrint("DEBUG: Peer List Update Error: $e");
      yield [];
    }
  }
});

/// Tracks whether the local node is in "Sleep Mode" (mesh-connected but low-activity).
final nodeSleepProvider = StateProvider<bool>((ref) => false);

/// Tracks which specific Conscia node is currently selected in the sidebar.
/// Null means no node is selected (main view shows chat or empty state).
final selectedNodeIdProvider = StateProvider<String?>((ref) => null);
