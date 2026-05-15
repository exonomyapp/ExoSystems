import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeographicContextScreen extends ConsumerWidget {
  const GeographicContextScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 EDUCATIONAL CONTEXT: Autonomy via Locality
    // Geographic routing (Spec 38) prevents "Cloud Colonialism" by allowing
    // operators to enforce content replication boundaries and latency-aware
    // peering based on physical-world proximity and policy.
    //
    // 💡 MENTOR TIP: Latency-Aware Federation
    // By setting a 'Latency Threshold', we ensure that the node only 
    // synchronizes with peers that are 'electrically close'. This prevents 
    // a slow or distant node from bottlenecking the gossip throughput of 
    // a high-performance local mesh.
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Geographic Context', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Define content locality rules and latency-aware routing policies.'),
          const SizedBox(height: 32),
          _buildPolicyCard(
            context,
            title: 'Replication Affinity',
            description: 'Prefer replicating metadata to nodes within your broad geographic region.',
            value: 'eu-central (Enabled)',
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            context,
            title: 'Latency Threshold',
            description: 'Maximum acceptable round-trip time for federation synchronization partners.',
            value: '200ms',
          ),
          const SizedBox(height: 16),
          _buildPolicyCard(
            context,
            title: 'Strict Locality',
            description: 'Prevent metadata from being replicated to nodes outside the declared region.',
            value: 'Disabled',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, {
    required String title,
    required String description,
    required String value,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
        ),
      ),
    );
  }
}
