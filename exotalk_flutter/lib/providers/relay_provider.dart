// = : = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
// relay_provider.dart — Relay Connection Monitor
// = : = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
//
// Relay nodes are peers that provide data persistence
// for the user's Willow replica when devices are offline.
//
// This provider polls the Rust engine every 500ms to check whether the
// associated relay node is reachable.
//
// See: docs/spec/10_identity_storage.md for the persistence model.
// = : = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';
import '../src/rust/api/network.dart';

/// Provider that periodically polls the Rust engine for the relay connection status.
final relayStatusProvider = StreamProvider<RelayStatus>((ref) async* {
  final identity = ref.watch(identityProvider);
  
  if (identity.activeDid == null) {
    yield const RelayStatus(nodeId: null, isConnected: false, activePeers: 0);
    return;
  }

  // Grace Period: 500ms to allow for initial handshake.
  yield const RelayStatus(nodeId: null, isConnected: false, activePeers: 0);
  await Future.delayed(const Duration(milliseconds: 500));

  // Yield the initial status with the engine's liveness check
  final rawInitial = await getRelayStatus();
  
  final initial = RelayStatus(
    nodeId: rawInitial.nodeId,
    isConnected: rawInitial.isConnected,
    activePeers: rawInitial.activePeers,
  );
  debugPrint("DEBUG: Relay Status Initial: connected=${initial.isConnected}");
  yield initial;

  // Then poll every 500ms
  while (true) {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final rawStatus = await getRelayStatus();

      final status = RelayStatus(
        nodeId: rawStatus.nodeId,
        isConnected: rawStatus.isConnected,
        activePeers: rawStatus.activePeers, 
      );
      yield status;
    } catch (e) {
      debugPrint("DEBUG: Relay Status Poll Error: $e");
      // If the engine is busy or restarting, just yield an offline status
      yield const RelayStatus(nodeId: null, isConnected: false, activePeers: 0);
    }
  }
});

/// Notifier to manage the associated relay ID
class AssociatedRelayNotifier extends Notifier<String?> {
  @override
  String? build() {
    // We load the initial state asynchronously
    _loadFromManifest();
    return null;
  }

  Future<void> _loadFromManifest() async {
    try {
      final manifest = await getDeviceManifest();
      state = manifest.associatedRelayId;
    } catch (_) {}
  }

  Future<void> associateNode(String nodeId) async {
    await setAssociatedRelay(nodeId: nodeId);
    state = nodeId;
  }
}

final associatedRelayProvider = NotifierProvider<AssociatedRelayNotifier, String?>(() {
  return AssociatedRelayNotifier();
});

/// Exposes the live roster of associated peers from the Rust engine.
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

/// Tracks which specific relay node is currently selected in the sidebar.
final selectedNodeIdProvider = StateProvider<String?>((ref) => null);
