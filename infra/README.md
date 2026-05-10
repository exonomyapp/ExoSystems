# 🏗️ Sovereign Infrastructure (Infra)

[ 🏠 Back to Exosystem Root ](../README.md)

This directory contains the supporting infrastructure required to maintain, monitor, and relay the Sovereign Exosystem mesh. It bridges the gap between the headless Rust engine and the public internet.

## Components

### 1. [ExoTech Bridge Monitor](bridge_monitor/README.md)
A high-fidelity Flutter dashboard for real-time telemetry and node health monitoring. It allows operators to:
- Verify P2P ingress/egress flows.
- Audit system logs via `journalctl` and `tail`.
- Switch between compact list and immersive card views.

### 2. [Signaling Relay](signaling_server.py)
A lightweight Python HTTP server that facilitates the initial WebRTC handshake (SDP exchange) between browser nodes and beacons. 
- **Port**: 8080 (Mapped to zrok).
- **Protocol**: HTTP/1.1 (Long-polling).

## Deployment

Infrastructure is deployed to the **Exonomy** node and exposed via **zrok**.

- **exotalk-signaling.service**: Manages the signaling relay.
- **exotalk-zrok.service**: Manages the public proxy tunnel.

---
*For architectural details on how these components fit into the mesh, see [Specification 01: System Architecture](../docs/spec/01_system_architecture.md).*
