# Peer-to-Peer Networking (Iroh)

## 2.2 Peer-to-Peer Networking (Iroh)

- **Direct P2P Connectivity:** Establish connections directly via UDP hole‑punching where network topologies allow.
- **DERP Relaying:** Utilize stateless DERP relays as "dumb pipes" to facilitate traffic traversing restrictive NATs.
- **Protocol Routing (ALPN):** We utilize the **Iroh Router** to multiplex multiple protocols over a single connection. Dedicated handlers are registered for:
  - `iroh-gossip`: Real-time chat announcements and sync triggers.
  - `iroh-blobs`: High-speed binary transmission for Willow content.
- **Topic-Based Swarms:** The networking engine dynamically manages Gossip topics per conversation, allowing **Conscia** to selectively archive and report on specific data streams.
