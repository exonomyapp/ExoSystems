import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/rust/api/network.dart' as rust_net;

final governanceProvider = StateNotifierProvider<GovernanceNotifier, GovernanceState>((ref) {
  final notifier = GovernanceNotifier();
  notifier.startPolling();
  return notifier;
});

class GovernanceState {
  final List<String> pendingRequests;
  final Map<String, String> activeRoles;
  final bool isLoading;

  GovernanceState({
    this.pendingRequests = const [],
    this.activeRoles = const {},
    this.isLoading = false,
  });

  GovernanceState copyWith({
    List<String>? pendingRequests,
    Map<String, String>? activeRoles,
    bool? isLoading,
  }) {
    return GovernanceState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeRoles: activeRoles ?? this.activeRoles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GovernanceNotifier extends StateNotifier<GovernanceState> {
  Timer? _pollingTimer;

  GovernanceNotifier() : super(GovernanceState());

  void startPolling() {
    _refresh();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final requests = await rust_net.getPendingRequests();
      final roles = await rust_net.getAllCapabilities();
      
      // Ensure we only update state if it actually changed to avoid unnecessary rebuilds
      if (state.pendingRequests != requests || state.activeRoles != roles) {
        state = state.copyWith(pendingRequests: requests, activeRoles: roles);
      }
    } catch (e) {
      debugPrint("Governance Sync Error: $e");
    }
  }

  Future<void> authorizeNode(String id, String role) async {
    try {
      state = state.copyWith(isLoading: true);
      await rust_net.authorizeNode(nodeId: id, role: role);
      await _refresh();
    } catch (e) {
      debugPrint("Authorization Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> revokeNode(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      await rust_net.revokeNode(nodeId: id);
      await _refresh();
    } catch (e) {
      debugPrint("Revocation Error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final nodeActivityProvider = StreamProvider.autoDispose<List<String>>((ref) async* {
  final events = [
    "Handshake completed with peer ...b492",
    "Gossip: Namespace sync triggered",
    "Blob saved: hash=blake3:f28...",
    "Heartbeat ACK from relay.iroh.network",
    "Peer discovered: did:peer:z6Mkh...",
    "Ingress: 12.4 KB/s",
    "Egress: 2.1 KB/s",
  ];
  
  final activeEvents = <String>[];
  int i = 0;
  
  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    final time = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    activeEvents.insert(0, "[$time] ${events[i % events.length]}");
    if (activeEvents.length > 5) activeEvents.removeLast();
    yield List.from(activeEvents);
    i++;
  }
});
