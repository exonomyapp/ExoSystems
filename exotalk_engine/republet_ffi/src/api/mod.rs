// =============================================================================
// api/ — Public FFI Surface (FRB-Scanned Modules)
// =============================================================================
//
// Every module declared here is scanned by flutter_rust_bridge codegen to
// generate corresponding Dart bindings. Only types and functions that should
// be callable from Flutter belong in these modules.
//
// Internal implementation details live in sibling modules at the crate root:
//   - network_internal.rs  — Iroh node lifecycle, gossip, blob store
//   - protocol_internal.rs — Willow message encoding, namespace derivation
// =============================================================================

pub mod simple;   // FRB init entrypoint
pub mod network;  // Network status, flight mode, blob operations
