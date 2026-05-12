import 'package:flutter/material.dart';

class ProposalInbox extends StatelessWidget {
  const ProposalInbox({super.key});

  // 🧠 EDUCATIONAL CONTEXT: Human-in-the-Loop (HITL) Adjudication
  // A core tenet of the Exosystem is that sovereign operators must manually 
  // review capability petitions from client applications (like Synesys) to prevent
  // autonomous network infiltration and ensure cryptographic authority remains intentional.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          _buildProposalCard(
            context,
            did: 'did:peer:1zQmTest...',
            client: 'Synesys iOS',
            roleRequested: 'Reader',
            timestamp: '2 mins ago',
          ),
          _buildProposalCard(
            context,
            did: 'did:peer:1zQmXYZ...',
            client: 'ExoTalk Desktop',
            roleRequested: 'Contributor',
            timestamp: '1 hour ago',
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(BuildContext context, {
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
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Deny'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
