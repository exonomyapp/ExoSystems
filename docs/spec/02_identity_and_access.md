# Identity and Access Management

## 2.1 Self-Authorial Identity (SSI)
- **Local Keypairs:** Users generate Ed25519 keypairs locally. The resulting `did:peer` (specifically `did:peer:2.Vz...`) serves as the immutable digital anchor.
- **Independence:** No central registry is required. Identity is claimed, not granted.

## 2.2 Proof-of-Visibility (Social Proofs)
To bridge independent DIDs with existing social platforms (X, GitHub, Mastodon), ExoTalk utilizes a three-generation proof system.

### 2.2.1 Proof Formats
1. **Legacy (`v1`)**:
    - **Format:** `exotalk-proof:v1:did={DID}:name={NAME}:sig={B58_SIG}`
    - **Description:** Verbose, human-readable format. Fits in large "About" or "Bio" sections (~190-200 chars).
2. **Full Compact (`etp1`)**:
    - **Format:** `etp1:{PUBKEY_B58}.{SIG_B58}`
    - **Description:** Optimized for Twitter/X bios. Truncates the `did:peer` prefix and focuses on the high-entropy components (~135 chars).
3. **Minimal Signature (`ets1`)**:
    - **Format:** `ets1:{SIG_B58}`
    - **Description:** Ultra-compact signature-only string. Designed for 100-character constrained fields like "Website" or restricted bios (~91 chars).

### 2.2.2 Dynamic Optimization Engine
The application implements a "Best-Fit" selection algorithm:
- The user provides a **Destination Character Limit**.
- The system evaluates all available formats in order of fidelity (Legacy -> Full -> Minimal).
- The most verbose format that satisfies the constraint is automatically selected.

## 2.3 Capability Delegation (Meadowcap)
- **Proof-based Access:** Permissions to read/write specific Willow ranges are carried by users as Meadowcap capability tokens.
- **Validation:** Peers validate these tokens locally against the publisher's public key. No central authority is consulted for access control.

## 2.4 The Duality of Trust: Proofs vs. Auth
To maintain resilience without sacrificing autonomy, ExoTalk bifurcates the concept of "Linked Accounts":

### 2.4.1 Outward Verification (ExoTalk → World) 
- **Role:** Reputation and Trust.
- **Mechanism:** Public Identity Proofs (`v1`, `etp1`, `ets1`).
- **Target:** The public social graph.
- **Goal:** PROVING to others who you are by leveraging your existing social reputation (e.g., "The person I'm chatting with is the real Isabella from Twitter").

### 2.4.2 Inward Recovery (World → ExoTalk)
- **Role:** Resilience and Continuity.
- **Mechanism:** OAuth-linked accounts (Google, Microsoft, GitHub, etc.). Credentials for these providers are securely provisioned via environment variables (e.g., `EXOTALK_GITHUB_CLIENT_ID`) in the client configuration, completely isolating secrets from the source code.
- **Implementation Guard:** The client UI enforces an `isConfigured` guard pattern. Social login buttons and account linking tiles remain gracefully disabled (displaying a "Not configured" state) until real OAuth credentials are detected, preventing broken flows involving development-time "mock" IDs.
- **Target:** The user's own recovery nodes (Conscia) and paired devices.
- **Goal:** PROVING to yourself (and your nodes) who you are in order to regain access to your independent identity after losing a device.
## 2.5 The Role of Conscia in Identity Recovery
While the `did:peer` is local-first, it can be optionally bound to centralized authenticators via Conscia:
1. **Binding:** A user performs an OAuth flow; ExoTalk generates a "Binding Proof" (a signature linking the DID to the OAuth `sub` ID).
2. **Persistence:** The Conscia node stores this binding metadata.
3. **Recovery:** Upon device loss, the user signs in with the same OAuth provider. Conscia verifies the token, recognizes the binding, and facilitates the secure re-synchronization of the user's repository and identity bundle to the new device.

## 2.6 Conscia Node Identity & Key Resolution
To participate as a first-class citizen in the Meadowcap capability system, every Conscia node must possess its own `did:peer` identity. This identity exists independently of Node Federation, allowing Conscia nodes to hold capabilities and interact simply as peers.

- **Node DID Generation:** Upon initialization, a node generates an isolated Ed25519 keypair and constructs a `did:peer` anchor.
- **Uniform Governance:** The Node DID allows organizational administrators to centrally manage multiple Conscia nodes from inside the ExoTalk client by delegating capabilities directly to the node's DID.
- **Key Resolution Tiers:** To solve the "Key Management Overhead" of isolated server nodes, Conscia implements two distinct levels of cryptographic support:
  1. **Peer Key Resolution (Non-Federated):** Two independent Conscia nodes can act as "mere peers," agreeing to securely hold each other's encrypted recovery keys. This lightweight agreement carries no obligation for data replication or cluster federation, but ensures that if one node suffers hardware failure, it can recover its identity from its peer.
  2. **Federated Key Resolution:** Engaged as part of a formal Node Federation (e.g., an HA Cluster). Nodes in a federation not only back up each other's keys but actively share state, telemetry, and capabilities.
- **UI Support:** The ExoTalk and ConSoul interfaces provide distinct workflows for engaging in lightweight Peer Key Resolution versus establishing a full Node Federation.
