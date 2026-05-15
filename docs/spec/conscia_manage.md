# Specification: Conscia Node Management UI

## Philosophy: Top-Down Management
The Conscia Management interface is designed to provide a standardized governance experience for standalone nodes and federated clusters. It follows a **Top-Down Information Hierarchy**, ensuring that the most critical, generally applicable information is surfaced first, while specialized administrative controls are selectively exposed at the bottom.

## UI Architecture

### 1. High-Priority Notifications (Top)
- **Purpose**: Immediate operator awareness for all access levels.
- **Abilities**:
    - Connectivity alerts (Node Offline/Unreachable).
    - Resource warnings (Storage Low, High CPU).
    - Security events (Unauthorized access attempts).

### 2. Node Identity & Pulse (Header)
- **Purpose**: Instant verification of the active server.
- **Features**:
    - **Node ID**: Truncated `did:peer` with copy-to-clipboard.
    - **Health Ring**: A pulsing visual indicator (Green: Optimal, Yellow: Warning, Red: Error).
    - **Live Status Badge**: Textual confirmation of mesh presence (ONLINE/OFFLINE).

### 3. Health Telemetry (General)
- **Purpose**: Impression of node performance for all mesh participants.
- **Metrics**:
    - **Mesh Peers**: Count of active P2P connections.
    - **Latency**: Round-trip time to the primary relay.
    - **Storage**: Current blob store volume.
    - **Addresses**: List of reachable public/private endpoints.

### 4. Operational Pulse (Privileged)
- **Purpose**: Real-time insight into the mesh's inner workings.
- **Exposure**:
    - **Admins**: Live telemetry stream of cryptographic handshakes, gossip syncs, and blob writes.
    - **Users**: Simplified "System Optimal" heartbeat animation.

### 5. Capability Governance (Admin Only)
- **Purpose**: Decentralized lifecycle management via Meadowcap.
- **Abilities**:
    - **Grant Capability**: Delegate roles (Admin, Write, Read) to other peers.
    - **Revoke Capability**: Broadcast "Tombstone" messages to invalidate compromised or unauthorized tokens.

### 6. Advanced Fleet Management (Future)
- **Purpose**: Scaling Conscia for professional infrastructure.
- **Roadmap**:
    - **HA Cluster Control**: Managing redundant node groups.
    - **AI Concierge Tuning**: Adjusting automated response and summarization parameters.
    - **Backup/Restore**: Cryptographic recovery of node state.

## Design Constraints
- **Typography**: Adheres to the global scaling system (Body: 16.0, Caption: 15.0 base).
- **Aesthetic**: Solid Identity (No transparency, high-contrast borders).
- **Accessibility**: 10% larger font scale by default to ensure operational clarity under stress.
