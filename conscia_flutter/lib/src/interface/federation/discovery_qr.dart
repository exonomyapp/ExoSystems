import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conscia_provider.dart';

class DiscoveryQr extends ConsumerWidget {
  const DiscoveryQr({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🧠 EDUCATIONAL CONTEXT: Layer A Proximity Discovery Protocol
    // This QR payload is optimized for high-speed physical scanning.
    // It allows an operator and a client to establish an immediate trusted 
    // connection via `did:peer` verification without relying on DNS or central routing.
    
    final asyncDiscovery = ref.watch(discoveryProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.topCenter,
      child: asyncDiscovery.when(
        data: (data) {
          final did = data['did'] ?? 'Offline';
          // In production, the URL is likely a stable zrok tunnel or local IP
          final discoveryUrl = 'https://conscianikolasee.share.zrok.io'; 
          final discoveryPayload = 'exonomy://discovery?did=$did&url=$discoveryUrl';

          return Column(
            children: [
              const Text('Scan with Synesys or ExoTalk to instantly establish a trusted connection.'),
              const SizedBox(height: 32),
              SizedBox(
                width: 300,
                height: 300,
                child: PrettyQrView.data(
                  data: discoveryPayload,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SelectableText(did),
              SelectableText(discoveryUrl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading discovery: $error')),
      ),
    );
  }
}
