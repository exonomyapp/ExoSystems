import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';

class TopologyGraph extends StatefulWidget {
  const TopologyGraph({super.key});

  @override
  State<TopologyGraph> createState() => _TopologyGraphState();
}

class _TopologyGraphState extends State<TopologyGraph> {
  // 🧠 EDUCATIONAL CONTEXT: Force-Directed Visualization
  // We use flutter_graph_view to visualize organic, multi-dimensional P2P mesh 
  // relationships. Static tables cannot adequately represent dynamic gossip routes,
  // cluster proximity, or relay node dependencies within a sovereign mesh topology.
  final Map<String, dynamic> _data = {};
  
  @override
  void initState() {
    super.initState();
    _buildMockTopology();
  }

  void _buildMockTopology() {
    var vertexes = <Map>{
      {'id': 'conscianikolasee', 'tag': 'Root Node'},
      {'id': 'exotalkberlin', 'tag': 'Peer Node'},
      {'id': 'relay-eu-central', 'tag': 'Relay'},
      {'id': 'community-node-1', 'tag': 'Peer Node'},
    };

    var edges = <Map>{
      {'srcId': 'conscianikolasee', 'dstId': 'exotalkberlin', 'edgeName': 'federation'},
      {'srcId': 'conscianikolasee', 'dstId': 'relay-eu-central', 'edgeName': 'federation'},
      {'srcId': 'relay-eu-central', 'dstId': 'community-node-1', 'edgeName': 'federation'},
    };

    _data['vertexes'] = vertexes;
    _data['edges'] = edges;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: FlutterGraphWidget(
        data: _data,
        algorithm: ForceDirected(),
        convertor: MapConvertor(),
        options: Options()
          ..enableHit = true
          ..panelDelay = const Duration(milliseconds: 500),
      ),
    );
  }
}
