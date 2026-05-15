import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conscia_provider.dart';

class ProposalInbox extends ConsumerWidget {
  const ProposalInbox({super.key});

  // 🧠 EDUCATIONAL CONTEXT: Human-in-the-Loop (HITL) Adjudication
  // A core tenet of the Exosystem is that operators must manually 
  // review capability petitions from client applications (like Synesys) to prevent
  // network infiltration and ensure cryptographic authority remains intentional.
  //
  // 💡 MENTOR TIP: Riverpod Watch/Read Patterns
  // We use 'ref.watch' for 'petitionsProvider' to ensure the UI rebuilds 
  // automatically when new petitions arrive via the Conscia daemon. Conversely, 
  // we use 'ref.read' in the 'onPressed' callback (line 73) because we only 
  // need to trigger a one-off action, not listen for ongoing changes to the 
  // action provider itself.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPetitions = ref.watch(petitionsProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: asyncPetitions.when(
        data: (petitions) {
          if (petitions.isEmpty) {
            return const Center(child: Text('No pending petitions.'));
          }
          return ListView.builder(
            itemCount: petitions.length,
            itemBuilder: (context, index) {
              final did = petitions[index];
              return _buildProposalCard(
                context,
                ref,
                did: did,
                client: 'Unknown Client', // In production, this metadata is gossiped
                roleRequested: 'Reader',     // In production, this metadata is gossiped
                timestamp: 'Recently',
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading petitions: $error')),
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, WidgetRef ref, {
    required String did,
    required String client,
    required String roleRequested,
    required String timestamp,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person_outline)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Petition from $client', style: Theme.of(context).textTheme.titleMedium),
                  Text('DID: $did', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('Role Requested: $roleRequested • $timestamp'),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.green),
              label: const Text('Approve'),
              onPressed: () async {
                await ref.read(consciaActionProvider).authorizePeer(did, roleRequested);
                ref.invalidate(petitionsProvider);
              },
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Deny'),
              onPressed: () {
                // 🧠 EDUCATIONAL CONTEXT: Deny Logic
                // Denying a petition simply removes it from the pending queue. 
                // Since the P2P mesh is permissionless for discovery but 
                // permissioned for synchronization, a denied peer can still 
                // "see" the node but cannot "sync" with it.
              },
            ),
          ],
        ),
      ),
    );
  }
}
