# 42. ExoTalk Client API Endpoints

This document enumerates the full spectrum of internal API endpoints exposed by the ExoTalk Rust backend (Engine) to the ExoTalk Flutter UI. These endpoints bridge the UI to the underlying Conscia daemon and must be fully implemented and testable before infrastructure simulation begins.

## 1. Identity & Profile Management

Endpoints responsible for local identity generation and profile synchronization via Willow.

*   `POST /api/identity/generate`
    *   **Description**: Generates a new Ed25519 keypair and establishing the local root identity.
*   `GET /api/identity/profile`
    *   **Description**: Retrieves the active profile metadata.
*   `PUT /api/identity/profile`
    *   **Description**: Updates profile metadata (name, bio, avatar hash) and signs the update into the local Willow store.
*   `POST /api/identity/device/link`
    *   **Description**: Initiates a device linking sequence using a localized Meadowcap token exchange.

## 2. Peer Discovery & Networking

Endpoints facilitating proximity-based and mesh-based peer discovery via Iroh.

*   `POST /api/network/proximity/scan`
    *   **Description**: Activates BLE/mDNS scanning to discover nearby Conscia nodes.
*   `POST /api/network/proximity/handshake`
    *   **Description**: Initiates an out-of-band key exchange (e.g., via scanned QR code) with a discovered peer.
*   `GET /api/network/peers`
    *   **Description**: Returns the list of currently connected peers and their latency metrics.
*   `DELETE /api/network/peers/{peer_id}`
    *   **Description**: Severs the connection with a specific peer.

## 3. Messaging & Synchronization

Endpoints for standard communication functions, reliant on the core sync layer.

*   `POST /api/messages/direct`
    *   **Description**: Dispatches an encrypted direct message to a specific peer.
*   `GET /api/messages/direct/{peer_id}`
    *   **Description**: Retrieves the message history for a specific 1:1 conversation.
*   `POST /api/messages/channel/{channel_id}`
    *   **Description**: Broadcasts a message to a specific group channel.
*   `GET /api/messages/channel/{channel_id}`
    *   **Description**: Retrieves the message history for a group channel.
*   `POST /api/sync/force`
    *   **Description**: Manually triggers a reconciliation cycle with connected peers.

## 4. Governance & Capabilities (Meadowcap)

Endpoints interfacing with the ConSoul architecture and Meadowcap credentialing.

*   `GET /api/governance/capabilities`
    *   **Description**: Retrieves the current set of active Meadowcap capabilities granted to the local identity.
*   `POST /api/governance/proposals`
    *   **Description**: Submits a new governance proposal to the community state.
*   `GET /api/governance/proposals`
    *   **Description**: Lists active proposals awaiting local vote.
*   `POST /api/governance/proposals/{proposal_id}/vote`
    *   **Description**: Casts a cryptographically signed vote on a specific proposal.

## 5. Infrastructure Integration

Endpoints utilized for interacting with external/managed infrastructure (e.g., pgEdge).

*   `GET /api/system/services`
    *   **Description**: Lists locally available managed services (e.g., the local pgEdge cluster connection status).
*   `POST /api/system/services/pgedge/query`
    *   **Description**: Internal diagnostic endpoint to issue arbitrary read queries against the local pgEdge node (restricted to authorized capabilities).
