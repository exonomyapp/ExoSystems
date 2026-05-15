# Walkthrough 08: Granular Traffic Control

The Granular Traffic Control system has been implemented, replacing the global network state with independent Inbound/Outbound toggles.

## Changes Implemented

### 1. Architectural Changes (Rust Core)
- **Identity Vault Schema Update**: The `IdentityVault` schema in `willow.rs` persists `ingress_enabled` and `egress_enabled` settings across reboots.
- **Network Logic**: Replaced the `FLIGHT_MODE` boolean with `INGRESS_PAUSED` and `EGRESS_PAUSED` in `network_internal.rs`.
- **Gossip Filtering**:
  - The Iroh connection loop ignores incoming connections when Ingress is paused.
  - `GossipEvent::Received` parsing is skipped when Ingress is paused.
  - Broadcast functionality skips network dispatch when Egress is paused.

### 2. UI Implementation (Flutter)
- Added a **Network Traffic Control** section to the account manager modal.
- Implemented toggles for:
   - **Inbound Sync**: Controls receiving messages and synchronization updates from the mesh.
   - **Outbound Sync**: Controls broadcasting messages and identity updates to peers.
- Integrated `ingressEnabled` and `egressEnabled` into the Riverpod layer in `chat_provider.dart`.

### 3. Documentation
- Updated `docs/spec/14_flight_mode.md` to reflect the Network Traffic Control specification.
- Added a `[!CAUTION]` block regarding passive inbound sync (Ingress enabled, Egress disabled), noting that it prevents negotiation of missing historical data ranges.

> [!NOTE]
> Verified via `cargo check`. Ensure `flutter_rust_bridge_codegen generate` is executed during the next build to update FFI definitions.

---
**Status**: Granular traffic control implementation complete.
