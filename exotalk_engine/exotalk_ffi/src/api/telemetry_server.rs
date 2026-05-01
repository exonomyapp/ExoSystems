// =============================================================================
// telemetry_server.rs — Automated Verification Sidecar (Spec 19)
// =============================================================================
// This module implements a lightweight HTTP server on port 11434. 
// It serves as a read-only sidecar for automated verification agents, 
// allowing them to audit the internal cryptographic state of the node 
// without requiring direct access to the P2P networking stack.
// =============================================================================
use axum::{routing::get, Json, Router};
use serde::Serialize;
use std::net::SocketAddr;
use tokio::net::TcpListener;
use exotalk_core::network_internal;
use crate::api::willow;

#[derive(Serialize)]
pub struct IdentityResponse {
    pub active_did: Option<String>,
    pub node_id: String,
    pub is_initialized: bool,
}

#[derive(Serialize)]
pub struct NetworkResponse {
    pub is_connected: bool,
    pub active_peers: u32,
    pub associated_conscia: Option<String>,
}

#[derive(Serialize)]
pub struct MeshResponse {
    pub ingress_paused: bool,
    pub egress_paused: bool,
    pub pending_requests_count: usize,
}

#[derive(Serialize)]
pub struct SystemResponse {
    pub os: String,
    pub arch: String,
    pub uptime_secs: u64,
}

static START_TIME: once_cell::sync::Lazy<std::time::Instant> = once_cell::sync::Lazy::new(std::time::Instant::now);

pub async fn start_telemetry_server() -> Result<(), String> {
    // Ensure START_TIME is initialized
    let _ = *START_TIME;

    let app = Router::new()
        .route("/api/identity", get(handle_identity))
        .route("/api/network", get(handle_network))
        .route("/api/mesh", get(handle_mesh))
        .route("/api/system", get(handle_system));

    let addr = SocketAddr::from(([127, 0, 0, 1], 11434));
    
    // Use tokio::spawn to run the server in the background without blocking the caller
    tokio::spawn(async move {
        match TcpListener::bind(addr).await {
            Ok(listener) => {
                tracing::info!("Telemetry API listening on {}", addr);
                if let Err(e) = axum::serve(listener, app).await {
                    tracing::error!("Telemetry server error: {}", e);
                }
            }
            Err(e) => {
                tracing::error!("Failed to bind telemetry server to {}: {}", addr, e);
            }
        }
    });

    Ok(())
}

async fn handle_identity() -> Json<IdentityResponse> {
    let node_id = network_internal::get_node_id().await;
    let active_did = willow::get_active_did_internal().await;
    
    Json(IdentityResponse {
        active_did,
        node_id,
        is_initialized: true,
    })
}

async fn handle_network() -> Json<NetworkResponse> {
    let (conscia_id, is_connected, active_peers) = network_internal::get_conscia_status().await;
    Json(NetworkResponse {
        is_connected,
        active_peers,
        associated_conscia: conscia_id,
    })
}

async fn handle_mesh() -> Json<MeshResponse> {
    let ingress_paused = network_internal::is_ingress_paused().await;
    let egress_paused = network_internal::is_egress_paused().await;
    let pending = network_internal::get_pending_requests().await.len();
    
    Json(MeshResponse {
        ingress_paused,
        egress_paused,
        pending_requests_count: pending,
    })
}

async fn handle_system() -> Json<SystemResponse> {
    Json(SystemResponse {
        os: std::env::consts::OS.to_string(),
        arch: std::env::consts::ARCH.to_string(),
        uptime_secs: START_TIME.elapsed().as_secs(),
    })
}
