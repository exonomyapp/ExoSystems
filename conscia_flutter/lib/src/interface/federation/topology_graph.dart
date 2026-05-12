import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conscia_provider.dart';

class TopologyGraph extends ConsumerWidget {
  const TopologyGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 EDUCATIONAL CONTEXT: Force-Directed Visualization
    // We use flutter_graph_view to visualize organic, multi-dimensional P2P mesh 
    // relationships. Static tables cannot adequately represent dynamic gossip routes,
    // cluster proximity, or relay node dependencies within a sovereign mesh topology.
    
    final asyncTopology = ref.watch(topologyProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: asyncTopology.when(
        data: (data) {
          return FlutterGraphWidget(
            data: data,
            algorithm: ForceDirected(),
            convertor: MapConvertor(),
            options: Options()
              ..enableHit = true
              ..panelDelay = const Duration(milliseconds: 500),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading topology: $error')),
      ),
    );
  }
}
