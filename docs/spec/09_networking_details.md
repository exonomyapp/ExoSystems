# Iroh Networking Details

## Peer‑to‑Peer Networking (Iroh) Details

- **Endpoint creation**: `iroh::Endpoint::builder()` is used to bind to a local UDP socket. The endpoint is configured with the node's Ed25519 secret key (derived from the `did:peer` keypair) so that the node's identity is cryptographically tied to the transport layer.
- **STUN discovery**: On startup the endpoint performs a STUN request to discover its public IP/port. If successful, direct UDP hole‑punching is attempted with discovered peers.
- **DERP fallback**: When direct connectivity fails, the endpoint automatically falls back to a DERP relay (default `relay.exotalk.tech`). The relay forwards encrypted packets without terminating TLS, preserving end‑to‑end encryption.
- **mDNS local discovery**: In LAN environments the endpoint broadcasts a small mDNS service (`_exotalk._udp.tech`) advertising its node ID. Peers listening on the same LAN can discover each other instantly without STUN.
- **Connection status API**: `get_node_status()` returns a JSON object:
  ```json
  {
    "connected_peers": 3,
    "relay_used": false,
    "latency_ms": 42,
    "public_addr": "203.0.113.5:54321"
  }
  ```
  This payload is marshaled by `flutter_rust_bridge` and exposed to Dart as a `NodeStatus` class.
