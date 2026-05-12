import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 EDUCATIONAL CONTEXT: Service Decoration Management
    // Conscia services are not "apps"—they are decorations (Spec 38) that 
    // enhance the mesh. This dashboard allows the operator to toggle 
    // cross-pollinating capabilities like Blind Indexing and Relay 
    // that serve the entire Exosystem application triad.
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Administration', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Manage and monitor active Conscia service decorations.'),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildServiceCard(
                  context,
                  title: 'Blind Indexing',
                  description: 'Manage metadata ingestion and public search visibility.',
                  icon: Icons.search,
                  isActive: true,
                ),
                _buildServiceCard(
                  context,
                  title: 'Relay (TURN/STUN)',
                  description: 'Configure bandwidth allocation and NAT traversal relay.',
                  icon: Icons.router,
                  isActive: true,
                ),
                _buildServiceCard(
                  context,
                  title: 'Cold Storage',
                  description: 'Manage persistent content pinning and storage inventory.',
                  icon: Icons.storage,
                  isActive: false,
                ),
                _buildServiceCard(
                  context,
                  title: 'Signaling',
                  description: 'Native SDP exchange for P2P connection establishment.',
                  icon: Icons.handshake,
                  isActive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 32, color: isActive ? Colors.blue : Colors.grey),
                Switch(value: isActive, onChanged: (v) {}),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Configure'),
            ),
          ],
        ),
      ),
    );
  }
}
