// =============================================================================
// api/ — Public FFI Surface (FRB-Scanned Modules)
// =============================================================================
//
// Every module declared here is scanned by flutter_rust_bridge codegen to
// generate corresponding Dart bindings. Only types and functions that should
// be callable from Flutter belong in these modules.
//
// 🧠 Educational Context: Post-Modularization Architecture
// Identity operations (DID, proofs, OAuth, verified links) have been
// extracted into the portable `exoauth_core` crate (`exoauth/rust/`).
// This crate now contains ONLY network-dependent operations:
//   - messaging  — Conversations, messages, Meadowcap capabilities
//   - network    — Iroh node lifecycle, peer discovery, blob store
//   - telemetry  — Port 11434 verification sidecar
//
// Internal implementation details live in sibling modules at the crate root:
//   - network_internal.rs  — Iroh node lifecycle, gossip, blob store
//   - protocol_internal.rs — Willow message encoding, namespace derivation
// =============================================================================

pub mod simple;          // FRB init entrypoint
pub mod messaging;       // Conversations, messages, capabilities (ex-willow.rs)
pub mod network;         // Network status, flight mode, blob operations
pub mod telemetry_server; // Port 11434 sidecar for agent verification
