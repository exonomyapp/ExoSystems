// =============================================================================
// network_internal.rs — Iroh Node Lifecycle & P2P Mesh Engine
// =============================================================================
//
// Hey! This is where the magic (networking) happens. This module manages the
// Iroh stack, which handles our global connectivity. 
//
// 💡 MENTOR TIP: We don't expose this directly to Flutter because Flutter's
// FFI (Foreign Function Interface) prefers simple types. `api/network.rs` 
// acts as the "receptionist" that translates Flutter's needs into these 
// low-level Rust calls.
//
// Architecture:
//   IrohNode (The persistent engine)
//     ├── endpoint  — The "Physical" connection (NAT traversal / QUIC)
//     ├── blobs     — The "Hard Drive" (Stores message payloads)
//     ├── gossip    — The "Loudspeaker" (Broadcasts short alerts to peers)
//     └── topics    — A map of everyone we're currently listening to
//
// Capability Governance (Meadowcap):
//   In this version, we've moved away from a hardcoded "Role" system.
//   Instead, we use CAPABILITY_STORE. When a peer joins, they "show" us 
//   a signed token. If the math checks out, we remember their permission
//   level (Read/Write/Admin) in memory for as long as we're online.
//
// See also: docs/spec/11_meadowcap_capabilities.md
// =============================================================================

use std::collections::HashMap;
use std::str::FromStr;
use std::sync::Arc;
use once_cell::sync::Lazy;
use tokio::sync::RwLock;
use futures_lite::StreamExt;
use iroh::PublicKey;
use iroh_gossip::net::GossipEvent;
use iroh_blobs::store::Store;

// (Removed unused crate::runtime import)
/// Static in-memory storage of verified access capabilities.
/// 💡 MENTOR TIP: We use a `Lazy<RwLock<...>>` here because this store needs
/// to be accessible from many different background tasks (threads) at once.
/// The `RwLock` ensures that many people can read permissions, but only one
/// can update them at a time, preventing "Race Conditions".
///
/// Maps [Namespace Hash] -> { [Delegatee DID] -> PermissionLevel }
pub static CAPABILITY_STORE: Lazy<RwLock<HashMap<[u8; 32], HashMap<String, crate::protocol_internal::PermissionLevel>>>> =
    Lazy::new(|| RwLock::new(HashMap::new()));

async fn save_capabilities() {
    let store = CAPABILITY_STORE.read().await;
    let path = std::path::Path::new("conscia_storage").join("capabilities.json");
    if let Ok(json) = serde_json::to_string(&*store) {
        let _ = std::fs::write(path, json);
    }
}

async fn load_capabilities() {
    let path = std::path::Path::new("conscia_storage").join("capabilities.json");
    if let Ok(json) = std::fs::read_to_string(path) {
        if let Ok(data) = serde_json::from_str::<HashMap<[u8; 32], HashMap<String, crate::protocol_internal::PermissionLevel>>>(&json) {
            let mut store = CAPABILITY_STORE.write().await;
            *store = data;
            tracing::info!("Restored {} capability namespaces from disk", store.len());
        }
    }
}

/// Tracker for the associated Conscia
static ASSOCIATED_CONSCIA: Lazy<RwLock<Option<PublicKey>>> = Lazy::new(|| RwLock::new(None));

/// Global store of pending join requests (node IDs).
pub static PENDING_REQUESTS: Lazy<RwLock<Vec<String>>> = Lazy::new(|| RwLock::new(Vec::new()));

/// Cached secret key for the beacon (used for signing delegations)
static BEACON_SECRET: Lazy<RwLock<Option<String>>> = Lazy::new(|| RwLock::new(None));

/// Cached DID for the beacon (used for discovering and signing)
static BEACON_DID: Lazy<RwLock<Option<String>>> = Lazy::new(|| RwLock::new(None));

pub async fn get_beacon_did() -> Option<String> {
    BEACON_DID.read().await.clone()
}

pub struct IrohNode {
    endpoint: iroh::Endpoint,
    blobs: iroh_blobs::store::fs::Store,
    gossip: iroh_gossip::net::Gossip,
    topics: Arc<RwLock<HashMap<[u8; 32], iroh_gossip::net::GossipSender>>>,
}

static NODE: Lazy<RwLock<Option<Arc<IrohNode>>>> = Lazy::new(|| RwLock::new(None));
static INGRESS_PAUSED: Lazy<RwLock<bool>> = Lazy::new(|| RwLock::new(false));
static EGRESS_PAUSED: Lazy<RwLock<bool>> = Lazy::new(|| RwLock::new(false));

pub async fn set_ingress_paused(paused: bool) {
    let mut mode = INGRESS_PAUSED.write().await;
    *mode = paused;
}

pub async fn is_ingress_paused() -> bool {
    let mode = INGRESS_PAUSED.read().await;
    *mode
}

pub async fn set_egress_paused(paused: bool) {
    let mut mode = EGRESS_PAUSED.write().await;
    *mode = paused;
}

pub async fn is_egress_paused() -> bool {
    let mode = EGRESS_PAUSED.read().await;
    *mode
}

pub async fn set_associated_conscia(node_id: String) -> Result<(), String> {
    let key = PublicKey::from_str(&node_id).map_err(|e| e.to_string())?;
    {
        let mut p = ASSOCIATED_CONSCIA.write().await;
        *p = Some(key);
    }
    
    // 💡 MENTOR TIP: In real-world networks (like mobile hotspots), discovery can be slow.
    // By explicitly calling `remote_info` or `connect`, we force Iroh to start
    // the dialer and handshake process immediately.
    let node_opt = NODE.read().await;
    if let Some(node) = node_opt.as_ref() {
        // 💡 MENTOR TIP: By adding the NodeAddr to the endpoint, we tell Iroh
        // that this peer is "interesting" and should be discovered via relays.
        let mut addr = iroh::NodeAddr::new(key);
        if let Ok(relay) = "https://euw1-1.relay.iroh.network./".parse() {
            addr = addr.with_relay_url(relay);
        }
        let _ = node.endpoint.add_node_addr(addr);

        let ep = node.endpoint.clone();
        tokio::spawn(async move {
            tracing::info!("Explicitly dialing associated Conscia node: {}", key);
            // Use the standard Iroh Gossip ALPN to ensure compatibility
            let _ = ep.connect(key, iroh_gossip::ALPN).await;
        });
    }

    Ok(())
}

/// Forces an immediate cryptographic handshake with the associated Conscia node.
/// 💡 MENTOR TIP: By default, Iroh handles re-dialing automatically, but 
/// for real-time UI responsiveness (<500ms), we manually trigger an 
/// endpoint connection to bypass the standard gossip/discovery delays.
pub async fn force_handshake() -> Result<(), String> {
    let target = {
        let p = ASSOCIATED_CONSCIA.read().await;
        *p
    };
    
    if let Some(key) = target {
        let node_opt = NODE.read().await;
        if let Some(node) = node_opt.as_ref() {
            let mut addr = iroh::NodeAddr::new(key);
            if let Ok(relay) = "https://euw1-1.relay.iroh.network./".parse() {
                addr = addr.with_relay_url(relay);
            }
            let _ = node.endpoint.add_node_addr(addr);

            let ep = node.endpoint.clone();
            tokio::spawn(async move {
                tracing::info!("Manually triggered dial to associated Conscia node: {}", key);
                let _ = ep.connect(key, iroh_gossip::ALPN).await;
            });
            Ok(())
        } else {
            Err("Network not initialized".to_string())
        }
    } else {
        Err("No associated Conscia node set".to_string())
    }
}

pub async fn get_conscia_status() -> (Option<String>, bool, u32) {
    let target = {
        let p = ASSOCIATED_CONSCIA.read().await;
        *p
    };
    let node_opt = NODE.read().await;
    
    if let Some(node) = node_opt.as_ref() {
        let peer_count = node.endpoint.remote_info_iter().count() as u32;
        let is_online = if let Some(target_id) = target {
             if let Some(info) = node.endpoint.remote_info(target_id) {
                !info.addrs.is_empty() || info.relay_url.is_some()
            } else {
                false
            }
        } else {
            false
        };
        (target.map(|t| t.to_string()), is_online, peer_count)
    } else {
        (target.map(|t| t.to_string()), false, 0)
    }
}

pub async fn get_peer_list() -> Vec<(String, Vec<String>)> {
    let node_lock = NODE.read().await;
    if let Some(n) = node_lock.as_ref() {
        n.endpoint.remote_info_iter()
            .map(|info| {
                let id = info.node_id.to_string();
                let addrs = info.addrs.iter().map(|a| a.addr.to_string()).collect();
                (id, addrs)
            })
            .collect()
    } else {
        vec![]
    }
}

pub async fn join_conversation_topic(namespace: [u8; 32]) -> Result<(), String> {
    let node_lock = NODE.read().await;
    let n = node_lock.as_ref().ok_or("Network not initialized")?;
    
    let topic_id = iroh_gossip::proto::TopicId::from(namespace);
    
    {
        let topics = n.topics.read().await;
        if topics.contains_key(&namespace) {
            return Ok(());
        }
    }
    
    // 💡 MENTOR TIP: Iroh 0.31 changed how subscriptions work. 
    // We "split" the topic into a Sender and a Receiver. 
    // We move the Receiver into a background task to listen for messages,
    // and keep the Sender in our `topics` map so we can broadcast later.
    let topic = n.gossip.subscribe(topic_id, vec![]).map_err(|e: anyhow::Error| e.to_string())?;
    let (sender, mut receiver) = topic.split();

    {
        let mut topics = n.topics.write().await;
        topics.insert(namespace, sender);
    }

    // 💡 MENTOR TIP: We use `tokio::spawn` here so this function can finish
    // immediately while a background worker keeps listening for new messages.
    tokio::spawn(async move {
        while let Some(Ok(event)) = receiver.next().await {
            if is_ingress_paused().await {
                continue; // Ignore gossip processing if ingress is paused
            }

            if let iroh_gossip::net::Event::Gossip(GossipEvent::Received(msg)) = event {
                let msg_content = msg.content.clone();
                if let Ok(json_str) = String::from_utf8(msg_content.to_vec()) {
                    // 1. Handle Join Requests
                    if json_str.contains("node_id") && json_str.contains("timestamp_ms") {
                        if let Ok(req) = serde_json::from_str::<crate::protocol_internal::JoinRequest>(&json_str) {
                            let mut pending = PENDING_REQUESTS.write().await;
                            if !pending.contains(&req.node_id) {
                                pending.push(req.node_id.clone());
                                tracing::info!("New JoinRequest queued for {}", req.node_id);
                            }
                            continue;
                        }
                    }

                    // 2. Handle Capability Tokens
                    if json_str.contains("delegator") && json_str.contains("delegatee") && json_str.contains("access_level") {
                        if let Ok(cap) = serde_json::from_str::<crate::protocol_internal::Capability>(&json_str) {
                            // 💡 MENTOR TIP: Always verify signatures *before* trusting the data!
                            if cap.verify() {
                                let mut store = CAPABILITY_STORE.write().await;
                                let ns_map = store.entry(cap.namespace).or_insert_with(HashMap::new);
                                ns_map.insert(cap.delegatee.clone(), cap.access_level.clone());
                                tracing::info!("Capability token stored and verified for {}", cap.delegatee);
                                drop(store);
                                save_capabilities().await;
                            } else {
                                tracing::warn!("Invalid capability token dropped — math doesn't work!");
                            }
                            continue;
                        }
                    }

                    // 3. Handle Revocation Tombstones
                    if json_str.contains("delegator") && json_str.contains("namespace") && !json_str.contains("access_level") {
                        if let Ok(tombstone) = serde_json::from_str::<crate::protocol_internal::RevocationTombstone>(&json_str) {
                             // 💡 MENTOR TIP: In this simple version, we trust the delegator for revocation.
                             // A real production system would verify the signature of the tombstone.
                             let mut store = CAPABILITY_STORE.write().await;
                             if let Some(ns_map) = store.get_mut(&tombstone.namespace) {
                                 if ns_map.remove(&tombstone.delegatee).is_some() {
                                     tracing::info!("Capability revoked via gossip tombstone for {}", tombstone.delegatee);
                                     drop(store);
                                     save_capabilities().await;
                                 }
                             }
                             continue;
                        }
                    }
                }
            }
        }
    });

    Ok(())
}

pub async fn get_pending_requests() -> Vec<String> {
    PENDING_REQUESTS.read().await.clone()
}

pub async fn get_all_capabilities() -> HashMap<String, String> {
    let store = CAPABILITY_STORE.read().await;
    let mut roles = HashMap::new();
    for ns_map in store.values() {
        for (did, level) in ns_map {
            roles.insert(did.clone(), format!("{:?}", level));
        }
    }
    roles
}

pub async fn authorize_node(node_id: String, role: String) -> Result<(), String> {
    let secret = {
        let s = BEACON_SECRET.read().await;
        s.clone().ok_or("Beacon secret not set")?
    };

    let level = match role.to_lowercase().as_str() {
        "admin" | "conscierge" | "owner" => crate::protocol_internal::PermissionLevel::Admin,
        "write" | "writer" | "delegate" => crate::protocol_internal::PermissionLevel::Write,
        _ => crate::protocol_internal::PermissionLevel::Read,
    };

    // Use a default global namespace for mesh-level governance
    let namespace = crate::protocol_internal::derive_namespace("conscia_mesh_governance");
    
    let delegator_did = get_beacon_did().await.ok_or("Beacon DID not set")?;
    
    let cap = crate::protocol_internal::delegate_capability(
        &delegator_did,
        &node_id,
        namespace,
        level.clone(),
        &secret,
    )?;

    // Store locally
    {
        let mut store = CAPABILITY_STORE.write().await;
        let ns_map = store.entry(namespace).or_insert_with(HashMap::new);
        ns_map.insert(node_id.clone(), level);
    }
    save_capabilities().await;

    // Broadcast
    let json = serde_json::to_string(&cap).map_err(|e| e.to_string())?;
    broadcast_raw_gossip(namespace, json).await?;

    // Remove from pending if present
    {
        let mut pending = PENDING_REQUESTS.write().await;
        pending.retain(|id| id != &node_id);
    }

    Ok(())
}

pub async fn revoke_node(node_id: String) -> Result<(), String> {
    let namespace = crate::protocol_internal::derive_namespace("conscia_mesh_governance");
    
    // 1. Remove locally
    {
        let mut store = CAPABILITY_STORE.write().await;
        if let Some(ns_map) = store.get_mut(&namespace) {
            ns_map.remove(&node_id);
        }
    }
    save_capabilities().await;

    // 2. Broadcast Tombstone
    let delegator_did = get_beacon_did().await.ok_or("Beacon DID not set")?;

    let tombstone = crate::protocol_internal::RevocationTombstone {
        delegator: delegator_did,
        delegatee: node_id.clone(),
        namespace,
        signature: vec![], // In this version, we don't sign tombstones yet
    };

    let json = serde_json::to_string(&tombstone).map_err(|e| e.to_string())?;
    broadcast_raw_gossip(namespace, json).await?;

    tracing::info!("Revocation broadcasted for node: {}", node_id);
    Ok(())
}

pub async fn request_access() -> Result<(), String> {
    let node_lock = NODE.read().await;
    let n = node_lock.as_ref().ok_or("Network not initialized")?;
    let node_id = n.endpoint.node_id().to_string();

    let namespace = crate::protocol_internal::derive_namespace("conscia_mesh_governance");

    // 💡 MENTOR TIP: A JoinRequest is a simple broadcast that tells the mesh
    // "I am here and I want to be part of the collective." 
    // The Conscia node listens for these and queues them for the operator.
    let req = crate::protocol_internal::JoinRequest {
        node_id: node_id.clone(),
        timestamp_ms: chrono::Utc::now().timestamp_millis(),
    };

    let json = serde_json::to_string(&req).map_err(|e| e.to_string())?;
    
    // Ensure we are subscribed to the topic before broadcasting
    join_conversation_topic(namespace).await?;
    
    broadcast_raw_gossip(namespace, json).await?;
    tracing::info!("Access request (petition) broadcasted for node: {}", node_id);
    
    Ok(())
}

async fn broadcast_raw_gossip(namespace: [u8; 32], content: String) -> Result<(), String> {
    let node_lock = NODE.read().await;
    let n = node_lock.as_ref().ok_or("Network not initialized")?;
    let topics = n.topics.read().await;
    let sender = topics.get(&namespace).ok_or("Not subscribed to topic")?;
    sender.broadcast(content.into_bytes().into()).await.map_err(|e: anyhow::Error| e.to_string())?;
    Ok(())
}

pub async fn shutdown_network() {
    let mut node_lock = NODE.write().await;
    if let Some(n) = node_lock.take() {
        tracing::info!("Shutting down active Iroh node...");
        // Explicitly close the endpoint to terminate the accept loop and release sockets
        let _ = n.endpoint.close().await;
        // In Iroh, dropping the Endpoint and Gossip instances cleans up the background tasks
        drop(n);
    }
}

pub async fn start_iroh_node(did: String, secret_key_b58: String) -> Result<(), String> {
    {
        if NODE.read().await.is_some() {
            return Ok(());
        }
    }
    
    {
        let mut s = BEACON_SECRET.write().await;
        *s = Some(secret_key_b58.clone());
    }

    {
        let mut d = BEACON_DID.write().await;
        *d = Some(did.clone());
    }

    load_capabilities().await;

    // Profile-specific storage path
    let safe_did = did.replace(":", "_");
    let mut storage_path = std::path::PathBuf::from("conscia_storage");
    storage_path.push("profiles");
    storage_path.push(&safe_did);
    storage_path.push("blobs");
    
    std::fs::create_dir_all(&storage_path).map_err(|e| format!("Failed to create storage dir: {}", e))?;
    
    // Add a small retry loop to allow the previous instance to release the file lock
    let mut blobs_opt = None;
    for i in 0..10 {
        match iroh_blobs::store::fs::Store::load(&storage_path).await {
            Ok(s) => {
                blobs_opt = Some(s);
                break;
            }
            Err(e) => {
                if i == 9 {
                    return Err(format!("Failed to load blob store after retries: {}", e));
                }
                tracing::warn!("Blob store locked, retrying in 100ms... (attempt {})", i + 1);
                tokio::time::sleep(std::time::Duration::from_millis(100)).await;
            }
        }
    }
    let blobs = blobs_opt.unwrap();

    // Bind the Iroh Node ID to the user's secret key
    let sk_bytes = bs58::decode(&secret_key_b58).into_vec().map_err(|e| format!("Invalid secret key b58: {}", e))?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Secret key length mismatch".to_string())?;
    let secret_key = iroh::SecretKey::from_bytes(&sk_arr);

    let endpoint = iroh::Endpoint::builder()
        .secret_key(secret_key)
        .discovery_n0() 
        .bind()
        .await
        .map_err(|e| format!("Failed to bind Iroh endpoint: {}", e))?;

    let gossip = iroh_gossip::net::Gossip::builder()
        .spawn(endpoint.clone())
        .await
        .map_err(|e: anyhow::Error| format!("Failed to spawn Gossip: {}", e))?;

    let endpoint_clone = endpoint.clone();
    let gossip_clone = gossip.clone();
    let blobs_clone = blobs.clone();
    
    tokio::spawn(async move {
        while let Some(incoming) = endpoint_clone.accept().await {
            if is_ingress_paused().await {
                tracing::info!("Ingress paused, ignoring incoming connection");
                continue;
            }
            
            let mut connecting = match incoming.accept() {
                Ok(c) => c,
                Err(e) => {
                    tracing::error!("Failed to accept incoming: {}", e);
                    continue;
                }
            };
            
            // In Iroh 0.31, ALPN is awaited on the connecting handle
            let alpn = connecting.alpn().await.unwrap_or_default();

            let conn = match connecting.await {
                Ok(c) => c,
                Err(e) => {
                    tracing::error!("Failed to connect: {}", e);
                    continue;
                }
            };
            
            // Peer ID is retrieved via a standalone endpoint function
            let remote_id = match iroh::endpoint::get_remote_node_id(&conn) {
                Ok(id) => id,
                Err(e) => {
                    tracing::warn!("Failed to retrieve peer ID: {}", e);
                    continue;
                }
            };

            if alpn == iroh_gossip::ALPN {
                let gossip = gossip_clone.clone();
                tokio::spawn(async move {
                    if let Err(e) = gossip.handle_connection(conn).await {
                        tracing::error!("Gossip connection error: {}", e);
                    }
                });
            } else if alpn == iroh_blobs::ALPN {
                let blobs = blobs_clone.clone();
                tokio::spawn(async move {
                    tracing::info!("Incoming blob request from {}", remote_id);
                    // Use the canonical iroh_blobs handler to serve local blobs
                    // It degrades gracefully if the payload is missing or peer disconnects.
                    iroh_blobs::provider::handle_connection(
                        conn,
                        blobs,
                        Default::default(),
                        iroh_blobs::util::local_pool::LocalPool::default().handle().clone(),
                    ).await;
                });
            }
        }
    });

    let node = Arc::new(IrohNode { endpoint, blobs, gossip, topics: Arc::new(RwLock::new(HashMap::new())) });
    
    let mut node_lock = NODE.write().await;
    *node_lock = Some(node.clone());
    
    // 💡 MENTOR TIP: The manifest is loaded BEFORE the node starts, which sets
    // ASSOCIATED_CONSCIA. Now that the node is actually up, we must explicitly
    // trigger the handshake dial if an ID was pre-loaded.
    let p = ASSOCIATED_CONSCIA.read().await;
    if let Some(key) = *p {
        let mut addr = iroh::NodeAddr::new(key);
        if let Ok(relay) = "https://euw1-1.relay.iroh.network./".parse() {
            addr = addr.with_relay_url(relay);
        }
        let _ = node.endpoint.add_node_addr(addr);
        let ep = node.endpoint.clone();
        tokio::spawn(async move {
            tracing::info!("Boot dial to associated Conscia node: {}", key);
            let _ = ep.connect(key, iroh_gossip::ALPN).await;
        });
    }

    Ok(())
}



pub async fn get_node_id() -> String {
    let node = NODE.read().await;
    if let Some(n) = node.as_ref() {
        n.endpoint.node_id().to_string()
    } else {
        "Not initialized".to_string()
    }
}

pub async fn save_blob(bytes: Vec<u8>) -> Result<String, String> {
    let node = NODE.read().await;
    let n = node.as_ref().ok_or("Network not initialized")?;
    
    let outcome = n.blobs.import_bytes(bytes.into(), iroh_blobs::BlobFormat::Raw).await.map_err(|e| e.to_string())?;
    Ok(outcome.hash().to_string())
}

/// Broadcasts a message hash across the gossip mesh.
/// 💡 MENTOR TIP: We only broadcast the HASH of the message, not the message itself.
/// Peers who see the hash can then decide to download the full blob from us
/// using Iroh's blob sync protocol. This keeps the gossip channel very fast!
pub async fn broadcast_message_hash(namespace: [u8; 32], hash_str: String) -> Result<(), String> {
    if is_egress_paused().await {
        tracing::warn!("Egress paused, skipping gossip broadcast");
        return Ok(());
    }

    let node_lock = NODE.read().await;
    let n = node_lock.as_ref().ok_or("Network not initialized")?;
    
    let topics = n.topics.read().await;
    let sender = topics.get(&namespace).ok_or("Not subscribed to this conversation topic")?;
    
    let hash = hash_str.parse::<iroh_blobs::Hash>().map_err(|e| e.to_string())?;
    sender.broadcast(hash.as_bytes().to_vec().into()).await.map_err(|e: anyhow::Error| e.to_string())?;
    Ok(())
}

pub async fn get_stats() -> HashMap<String, String> {
    let node = NODE.read().await;
    let mut stats = HashMap::new();
    if let Some(n) = node.as_ref() {
        stats.insert("node_id".to_string(), n.endpoint.node_id().to_string());
        stats.insert("status".to_string(), "Online".to_string());
        
        // 1. Local Bind (LAN)
        let (v4, _) = n.endpoint.bound_sockets();
        stats.insert("local_port".to_string(), v4.port().to_string());

        // 2. Relay Connectivity (Internet)
        if let Ok(Some(url)) = n.endpoint.home_relay().get() {
            stats.insert("home_relay".to_string(), url.to_string());
        } else {
            stats.insert("home_relay".to_string(), "None".to_string());
        }

        // 3. Mesh Peering
        let peers_count = n.endpoint.remote_info_iter().count();
        stats.insert("active_peers".to_string(), peers_count.to_string());

        // 4. Gossip Subscriptions
        let topics = n.topics.read().await;
        stats.insert("topics_count".to_string(), topics.len().to_string());

        // 🧠 EDUCATIONAL CONTEXT: We renamed 'blob_count' to 'storage_status' to elevate 
        // the API from an implementation-detail (blobs) to a functional concept (storage).
        // This aligns with the "Process IS The Product" vision by making the telemetry
        // human-readable for the Sovereign Dashboard.
        stats.insert("storage_status".to_string(), "Active".to_string());
    } else {
        stats.insert("status".to_string(), "Offline".to_string());
    }
    stats
}
#[cfg(test)]
mod diagnostics {
    use super::*;
    #[tokio::test]
    async fn print_local_node_id() {
        let secret_key_b58 = "CVh7w1QW9GdThiRskD5SYtCyzGLteP4BC6CXR94CF26u";
        let sk_bytes = bs58::decode(&secret_key_b58).into_vec().unwrap();
        let sk_arr: [u8; 32] = sk_bytes.try_into().unwrap();
        let secret_key = iroh::SecretKey::from_bytes(&sk_arr);
        println!("DIAGNOSTIC_NODE_ID: {}", secret_key.public().to_string());
    }
    #[tokio::test]
    async fn check_status() {
        let stats = get_stats().await;
        println!("NETWORK_STATS: {:?}", stats);
        let (id, online, peers) = get_conscia_status().await;
        println!("CONSCIA_STATUS: id={:?} online={} peers={}", id, online, peers);
    }

    #[tokio::test]
    async fn test_send_actual_request() -> Result<(), String> {
        let did = "did:peer:exocracy_verify".to_string();
        let secret = "CVh7w1QW9GdThiRskD5SYtCyzGLteP4BC6CXR94CF26u".to_string(); // Valid different key
        start_iroh_node(did, secret).await?;
        
        let stats = get_stats().await;
        let local_id = stats.get("node_id").unwrap();
        println!("LOCAL_NODE_ID_FOR_VERIFY: {}", local_id);
        
        // Connect to LOCAL conscia
        let remote_id = "2f4300ae2c116d3c0f87cea35cc0254900a217558878d55010e435e30b0cc9b4";
        set_associated_conscia(remote_id.to_string()).await?;
        
        tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;
        
        for i in 0..10 {
            println!("Sending attempt {}...", i);
            request_access().await?;
            tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;
        }
        
        Ok(())
    }
}
