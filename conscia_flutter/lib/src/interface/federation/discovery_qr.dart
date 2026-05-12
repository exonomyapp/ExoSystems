import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class DiscoveryQr extends StatelessWidget {
  const DiscoveryQr({super.key});

  @override
  Widget build(BuildContext context) {
    // 🧠 EDUCATIONAL CONTEXT: Layer A Proximity Discovery Protocol
    // This QR payload is optimized for high-speed physical scanning.
    // It allows an operator and a client to establish an immediate trusted 
    // connection via `did:peer` verification without relying on DNS or central routing.
    // In production, this data string will be the Base64 JSON payload of the node's /api/discovery response
    final String discoveryPayload = 'exonomy://discovery?did=did:peer:1zQmNode&url=https://conscianikolasee.share.zrok.io';

    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.topCenter,
      child: Column(
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
                // We can add an image here later if we want the Pappus logo in the center
                // image: PrettyQrDecorationImage(image: AssetImage('assets/pappus.png')),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SelectableText('did:peer:1zQmNode...'),
          const SelectableText('https://conscianikolasee.share.zrok.io'),
        ],
      ),
    );
  }
}
