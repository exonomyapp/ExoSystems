import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/rust/api/network.dart';

class PeerListSettings {
  final Map<String, double> columnWidths;
  final String sortColumn;
  final bool sortAscending;

  PeerListSettings({
    required this.columnWidths,
    required this.sortColumn,
    required this.sortAscending,
  });

  PeerListSettings copyWith({
    Map<String, double>? columnWidths,
    String? sortColumn,
    bool? sortAscending,
  }) {
    return PeerListSettings(
      columnWidths: columnWidths ?? this.columnWidths,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

class PeerListSettingsNotifier extends StateNotifier<PeerListSettings> {
  PeerListSettingsNotifier() : super(PeerListSettings(
    columnWidths: {
      'node_id': 300.0,
      'addresses': 400.0,
    },
    sortColumn: 'node_id',
    sortAscending: true,
  ));

  void updateWidth(String column, double width) {
    state = state.copyWith(
      columnWidths: Map.from(state.columnWidths)..[column] = width.clamp(50.0, 800.0),
    );
  }

  void toggleSort(String column) {
    if (state.sortColumn == column) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortColumn: column, sortAscending: true);
    }
  }
}

final peerListSettingsProvider = StateNotifierProvider<PeerListSettingsNotifier, PeerListSettings>((ref) {
  return PeerListSettingsNotifier();
});

// Provider to fetch the actual peer list from Rust with polling
final peerListProvider = StreamProvider<List<PeerInfo>>((ref) async* {
  while (true) {
    try {
      final peers = await getPeerList();
      yield peers;
    } catch (e) {
      // In case of error, yield empty or keep last? 
      // StreamProvider will handle the error if we throw.
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});
