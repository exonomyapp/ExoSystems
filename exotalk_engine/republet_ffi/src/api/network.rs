// =============================================================================
// network.rs — Flutter-Facing Network API (FRB Bridge Layer)
// =============================================================================
//
// This module is the public-facing API for all network operations. It acts as
// a thin pass-through between Flutter (via flutter_rust_bridge) and the actual
// Iroh networking logic in `network_internal.rs`.
//
// Why the split? FRB codegen scans `src/api/*.rs` for public function signatures
// and generates Dart bindings. By keeping the FRB-visible surface here and the
// heavy implementation in `network_internal.rs`, we avoid exposing Iroh's complex
// internal types (Endpoint, Gossip, Store) to the Dart side.
//
// See: docs/spec/11_flight_mode.md for the "App Flight Mode" feature.
// =============================================================================

use exotalk_core::network_internal;

pub struct ConsciaStatus {
    pub node_id: Option<String>,
    pub is_connected: bool,
    pub active_peers: u32,
}

pub async fn start_iroh_node(did: String, secret_key_b58: String) -> Result<(), String> {
    network_internal::start_iroh_node(did, secret_key_b58).await
}

pub async fn get_node_id() -> String {
    network_internal::get_node_id().await
}

pub async fn save_blob(bytes: Vec<u8>) -> Result<String, String> {
    network_internal::save_blob(bytes).await
}

pub async fn broadcast_message_hash(namespace: [u8; 32], hash_str: String) -> Result<(), String> {
    network_internal::broadcast_message_hash(namespace, hash_str).await
}

pub async fn join_conversation_topic(namespace: [u8; 32]) -> Result<(), String> {
    network_internal::join_conversation_topic(namespace).await
}

pub async fn set_associated_conscia(node_id: String) -> Result<(), String> {
    network_internal::set_associated_conscia(node_id).await
}



pub async fn get_conscia_status() -> ConsciaStatus {
    let (node_id, is_connected, active_peers) = network_internal::get_conscia_status().await;
    ConsciaStatus { node_id, is_connected, active_peers }
}
