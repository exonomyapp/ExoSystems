# Spec 37: Sovereign Infrastructure & Persistence

## 1. Overview
This specification defines the standard for "Boot-Stable" sovereign infrastructure within the Exonomy ecosystem. It ensures that a node can survive a cold reboot and restore all public-facing services (Signaling, Mesh, Dashboard) at deterministic, permanent URLs without human intervention.

## 2. Service Topology
The node infrastructure consists of three primary layers:

| Layer | Service | Port | Role |
| :--- | :--- | :--- | :--- |
| **Logic** | `exotalk-signaling` | 8080 | WebRTC Matchmaker (Messenger) |
| **Engine** | `exotalk-conscia` | 3000 | P2P Mesh Node & Dashboard (Engine) |
| **Access** | `exotalk-zrok` | N/A | Stable Tunneling (The Front Door) |
| **Observability** | `minikube` | N/A | Telemetry & Health Monitoring |

## 3. Public Naming Standard (Forever URLs)
To maintain professional branding and cross-reboot stability, all public endpoints must use **Reserved Service Tokens** under the zrok v1 Stable branch.

### 3.1. Token Format
Tokens must be strictly **lowercase alphanumeric** (no dots, hyphens, or underscores).
*   **Standard**: `<service_prefix><nodename>`
*   **Signaling Prefix**: `exotalk`
*   **Conscia Prefix**: `conscia`

### 3.2. Current Deployment (Berlin Node)
*   **Relay URL**: `https://exotalkberlin.share.zrok.io`
*   **Node URL**: `https://conscianikolasee.share.zrok.io`

## 4. The Signaling vs. WebRTC Boundary
The infrastructure maintains a strict separation of concerns for WebRTC connectivity:
*   **The Signaling Relay** is protocol-agnostic. It merely exchanges SDP/ICE metadata. It does not process WebRTC media or data.
*   **The End-Points** (Conscia Node / Bridge UI) are the sole processors of the WebRTC protocol.
*   **Failure Recovery**: If the Signaling Relay fails, existing WebRTC connections persist, but new handshakes will fail until the relay's zrok tunnel re-establishes.

## 5. Persistence & Lifecycle
All services are managed via `systemd` with a `Restart=always` policy.

### 5.1. Boot Sequence
1.  **Network Initialization**: System awaits hardware link.
2.  **Core Services**: `exotalk-signaling` and `exotalk-conscia` start on localhost.
3.  **Tunnel Attachment**: `exotalk-zrok` and `exotalk-zrok-conscia` attach to the reserved tokens.
4.  **Observability**: `minikube` starts in the background to provide a telemetry baseline.

## 6. Interoperability (CORS)
To enable external UIs (Bridge Monitor, Third-party Dashboards) to communicate with the node, the Conscia HTTP API must implement a permissive CORS policy allowing 'Any' origin, effectively turning the node into an "Open Diagnostic Endpoint" for authorized users.
