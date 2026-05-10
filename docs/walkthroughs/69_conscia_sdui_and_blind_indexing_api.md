# Walkthrough 69: Conscia SDUI and Blind Indexing API

## Overview

The `exotalk_engine/conscia` Axum API has been expanded to act as the HTTP gateway for decoupled external host applications (e.g., ThreeSteps, RepubLet, Exocracy). These updates formally implement the **Application Triad Architecture**, providing external apps with the endpoints needed to discover the mesh, govern access, and perform global metadata searches via a **Server-Driven UI (SDUI)** model.

## Implementation Details

All endpoints have been integrated into the central Axum `Router` in `exotalk_engine/conscia/src/main.rs`.

### 1. Server-Driven UI (SDUI) & Topology
* **`GET /api/capabilities`**
  * Serves topology metrics, performance constraints, and declarative UI widget blueprints (`sdui_widgets`).
  * Enables dynamic, resilient client UI rendering decoupled from internal network logic.
  * Host applications act as pure rendering engines, painting only the widgets the node instructs.

### 2. Mesh Discovery
* **`GET /api/discovery`**
  * Unauthenticated access to the node's public identity (DID), Iroh Node ID, and semantic version.
  * Returns the actual node DID from `BEACON_DID`, not a hardcoded string.

### 3. Capability Governance
* **`POST /api/capabilities/petition`**
  * Provides a REST-based pathway for external DIDs (without the Iroh stack) to inject `JoinRequest` structures into the same `PENDING_REQUESTS` queue used by gossip-based petitions.
* **`POST /api/capabilities/verify`**
  * Enables a DID to query its active `PermissionLevel` directly from the node's internal `CAPABILITY_STORE`.

### 4. Blind Indexing
* **`POST /api/index/metadata`**
  * Ephemeral, memory-safe mechanism (`RwLock<Vec<MetadataPayload>>`) to receive and index signed public metadata tags without decrypting the underlying content.
* **`GET /api/index/search`**
  * Case-insensitive substring search across the local metadata index, returning mapped DIDs and content hashes for requested tags.

### 5. Identity Hardening (Placeholder Purge)
All hardcoded identity strings across the monorepo have been replaced with real Ed25519 key generation:
* **`conscia/src/main.rs`**: The onboarding wizard now generates a real Ed25519 keypair on first boot.
* **`exotalk_core/src/network_internal.rs`**: Introduced `BEACON_DID` global. The `authorize_node()` and `revoke_node()` functions now read the actual DID from this source of truth.
* **`exotalk_wasm/src/lib.rs`**: `synthesize_did()` generates a real Ed25519 keypair inside the browser sandbox.

### 6. Documentation Updates
* **Spec 19** (`docs/spec/19_verification_telemetry_api.md`): Added a comprehensive endpoint reference table for the Conscia Node API (Port 3000).
* **Spec 11** (`docs/spec/11_meadowcap_capabilities.md`): Documented the HTTP petition path alongside the existing gossip-based path in the Federated Join Requests section.

## Validation Results

* **Compilation**: `cargo check` passes cleanly on the `conscia` crate with zero errors.
* **Memory Safety**: Cross-thread concurrency for `METADATA_INDEX` and `BEACON_DID` secured via `once_cell::sync::Lazy` and `tokio::sync::RwLock`.
* **CORS**: The `CorsLayer` covers all Phase 4 routes.
* **Placeholder Audit**: `grep -ri placeholder` returns zero results across all `.rs` files in `exotalk_engine/`.
