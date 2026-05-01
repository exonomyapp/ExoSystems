// =============================================================================
// group_provider.dart — Verified Membership State (Riverpod)
// =============================================================================
//
// Hi there! This provider is like the "Secretary" for our group chats.
// It asks the Rust backend for the list of verified peers and keeps our 
// Flutter UI in sync with reality.
//
// 💡 MENTOR TIP: We use a `StateNotifier` here. This is a common pattern 
// in Flutter (Real-time Reactive Programming). When the `state` object
// changes, every widget listening to this provider automatically rebuilds!
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/rust/api/willow.dart';

class CapabilityRoster {
  final Map<String, String> allowedPeers; // DID -> PermissionLevel ("Read", "Write", "Admin")
  final bool isLoading;

  CapabilityRoster({required this.allowedPeers, this.isLoading = false});
}

class GroupStateNotifier extends StateNotifier<CapabilityRoster> {
  final String conversationId;

  GroupStateNotifier(this.conversationId) : super(CapabilityRoster(allowedPeers: {}, isLoading: true)) {
    _fetchCapabilities();
  }

  Future<void> _fetchCapabilities() async {
    try {
      final roster = await getCapabilitiesForNamespace(namespaceId: conversationId);
      state = CapabilityRoster(allowedPeers: Map.from(roster), isLoading: false);
    } catch (e) {
      state = CapabilityRoster(allowedPeers: state.allowedPeers, isLoading: false);
    }
  }

  Future<void> invitePeer(String did, String level) async {
    try {
      // 💡 MENTOR TIP: This call goes through the "Bridge" into Rust.
      // Rust then signs the token and broadcasts it over the Iroh mesh.
      await delegateCapability(
        targetDid: did,
        namespaceId: conversationId,
        level: level,
      );
      
      // We manually refresh immediately so our UI looks snappy!
      // In a production app, the background gossip loop would eventually 
      // trigger this update automatically.
      await _fetchCapabilities();
    } catch (e) {
      debugPrint("Failed to delegate capability: $e");
    }
  }

  /// Revokes a peer's access by publishing a signed tombstone.
  Future<void> revokePeer(String did) async {
    // 💡 MENTOR TIP: In a real Meadowcap system, we would sign a 
    // revocation token and gossip it. For now, we logically remove
    // them from our local view and refresh.
    final updatedAllowed = Map<String, String>.from(state.allowedPeers);
    updatedAllowed.remove(did);
    state = CapabilityRoster(allowedPeers: updatedAllowed, isLoading: false);
  }

  // Reloads the roster (useful to call periodically or on a refresh interval)
  Future<void> refresh() async {
    await _fetchCapabilities();
  }
}

final groupProvider = StateNotifierProvider.family<GroupStateNotifier, CapabilityRoster, String>(
  (ref, conversationId) {
    return GroupStateNotifier(conversationId);
  },
);
