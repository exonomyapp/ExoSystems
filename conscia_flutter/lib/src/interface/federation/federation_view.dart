import 'package:flutter/material.dart';
import 'topology_graph.dart';
import 'proposal_inbox.dart';
import 'discovery_qr.dart';

class FederationView extends StatelessWidget {
  const FederationView({super.key});

  // 🧠 EDUCATIONAL CONTEXT: Meta-Management Dashboard
  // As per Spec 40, this view serves as the primary operator interface for P2P Metamanagement.
  // It organizes Mesh Topology monitoring, HITL (Human-in-the-Loop) capability
  // proposal reviews, and Proximity Discovery (Layer A) presentation.
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0).copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Federation Administration', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('P2P Mesh Topology, HITL capability proposals, and Proximity Discovery.'),
                const SizedBox(height: 16),
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(icon: Icon(Icons.hub), text: 'Topology Graph'),
                    Tab(icon: Icon(Icons.inbox), text: 'Proposal Inbox'),
                    Tab(icon: Icon(Icons.qr_code_scanner), text: 'Proximity Discovery'),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TopologyGraph(),
                ProposalInbox(),
                DiscoveryQr(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
