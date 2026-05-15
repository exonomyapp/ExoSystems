// =============================================================================
// messaging.rs — Conversation & Message Engine (Post-Modularization)
// =============================================================================
//
// Separation of Concerns
// This module contains the chat/messaging logic that depends on 
// the P2P network layer (Iroh).
//
// Identity operations (DID generation, proofs, OAuth links, verified links)
// live in the portable `exoauth_core` crate at `exoauth/rust/`.
//
// Key Design Decision:
//   - `init_database(did, secret)` takes explicit identity parameters.
//   - `delegate_capability` callers provide credentials rather than relying
//     on shared mutable identity storage.
// =============================================================================

use tokio::sync::RwLock;
use serde::{Serialize, Deserialize};
use once_cell::sync::Lazy;
use exotalk_core::protocol_internal::{Capability, PermissionLevel};
use crate::api::network;
use exotalk_core::protocol_internal;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Conversation {
    pub id: String,
    pub title: String,
    pub peers: Vec<String>,
    pub last_active: i64,
    pub unread_count: u32,
    pub avatar: String,
    pub is_group: bool,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Message {
    pub id: String,
    pub conversation_id: String,
    pub author_did: String,
    pub content: String,
    pub timestamp_ms: i64,
}

static DB_MESSAGES: Lazy<RwLock<Vec<Message>>> = Lazy::new(|| RwLock::new(Vec::new()));
static DB_CONVERSATIONS: Lazy<RwLock<Vec<Conversation>>> = Lazy::new(|| RwLock::new(Vec::new()));

async fn storage_path(filename: &str) -> std::path::PathBuf {
    let mut p = std::path::PathBuf::from("exotalk_storage");
    let _ = std::fs::create_dir_all(&p);
    p.push(filename);
    p
}

async fn save_db_to_disk() {
    if let Ok(c) = serde_json::to_string(&*DB_CONVERSATIONS.read().await) {
        let _ = std::fs::write(storage_path("db_conversations.json").await, c);
    }
    if let Ok(m) = serde_json::to_string(&*DB_MESSAGES.read().await) {
        let _ = std::fs::write(storage_path("db_messages.json").await, m);
    }
}

pub async fn init_database(did: String, secret: String) -> Result<bool, String> {
    network::start_iroh_node(did, secret).await?;

    if let Ok(data) = std::fs::read_to_string(storage_path("db_conversations.json").await) {
        if let Ok(parsed) = serde_json::from_str::<Vec<Conversation>>(&data) {
            let mut db_c = DB_CONVERSATIONS.write().await;
            *db_c = parsed;
        }
    }
    
    if let Ok(data) = std::fs::read_to_string(storage_path("db_messages.json").await) {
        if let Ok(parsed) = serde_json::from_str::<Vec<Message>>(&data) {
            let mut db_m = DB_MESSAGES.write().await;
            *db_m = parsed;
        }
    }
    
    Ok(true)
}

pub async fn fetch_conversations() -> Vec<Conversation> {
    let db = DB_CONVERSATIONS.read().await;
    db.clone()
}

pub async fn send_message(conversation_id: String, author_did: String, content: String) -> Message {
    let timestamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;
    
    let encoded = protocol_internal::encode_message(&content, timestamp).unwrap();
    let blob_hash = network::save_blob(encoded).await.expect("Failed to persist message blob");
    let namespace = protocol_internal::derive_namespace(&conversation_id);
    network::broadcast_message_hash(namespace, blob_hash).await.expect("Failed to broadcast message announcement");

    let msg = {
        let mut db = DB_MESSAGES.write().await;
        let m = Message {
            id: format!("msg_{}", db.len()),
            conversation_id,
            author_did,
            content,
            timestamp_ms: timestamp,
        };
        db.push(m.clone());
        m
    };
    
    save_db_to_disk().await;
    msg
}

pub async fn get_messages_for_conversation(convo_id: String) -> Vec<Message> {
    let db = DB_MESSAGES.read().await;
    db.iter().filter(|m| m.conversation_id == convo_id).cloned().collect()
}

pub async fn create_conversation(title: String, peers: Vec<String>) -> Conversation {
    let id_str = {
        let db = DB_CONVERSATIONS.read().await;
        format!("convo_{}", db.len())
    };
    
    let namespace = protocol_internal::derive_namespace(&id_str);
    let _ = network::join_conversation_topic(namespace).await;

    let avatar_str = format!("https://picsum.photos/seed/{}/200/200", id_str);
    let c = Conversation {
        id: id_str,
        title,
        peers,
        last_active: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64,
        unread_count: 0,
        avatar: avatar_str,
        is_group: false,
    };
    
    {
        let mut db = DB_CONVERSATIONS.write().await;
        db.push(c.clone());
    }
    
    save_db_to_disk().await;
    c
}

pub async fn delete_conversation(convo_id: String) {
    {
        let mut db = DB_CONVERSATIONS.write().await;
        db.retain(|c| c.id != convo_id);
    }
    
    {
        let mut db = DB_MESSAGES.write().await;
        db.retain(|m| m.conversation_id != convo_id);
    }
    
    save_db_to_disk().await;
}

pub async fn delegate_capability(
    delegator_did: String,
    delegator_secret: String,
    target_did: String,
    namespace_id: String,
    level: String,
) -> Result<String, String> {
    if delegator_secret.is_empty() {
        return Err("No active identity to delegate from".into());
    }

    let sk_bytes = bs58::decode(&delegator_secret).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Invalid secret key length".to_string())?;
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&sk_arr);
    use ed25519_dalek::Signer;

    let access_level = match level.as_str() {
        "Read" => PermissionLevel::Read,
        "Write" => PermissionLevel::Write,
        "Admin" => PermissionLevel::Admin,
        _ => return Err("Invalid permission level".to_string()),
    };

    let namespace = exotalk_core::protocol_internal::derive_namespace(&namespace_id);

    let mut cap = Capability {
        delegator: delegator_did.clone(),
        delegatee: target_did,
        namespace,
        access_level: access_level.clone(),
        signature: vec![],
    };

    let ns_b58 = bs58::encode(&cap.namespace).into_string();
    let payload = format!("{}:{}:{}:{:?}", cap.delegator, cap.delegatee, ns_b58, cap.access_level);
    let signature = signing_key.sign(payload.as_bytes());
    cap.signature = signature.to_bytes().to_vec();

    serde_json::to_string(&cap).map_err(|e| e.to_string())
}

pub async fn verify_capability(cap_json: String) -> Result<bool, String> {
    let cap: Capability = serde_json::from_str(&cap_json).map_err(|e| e.to_string())?;
    
    let pk_b58 = match cap.delegator.strip_prefix("did:peer:2.Vz") {
        Some(s) => s,
        None => return Err("Invalid delegator DID format".to_string()),
    };
    
    let pk_bytes = bs58::decode(pk_b58).into_vec().map_err(|e| e.to_string())?;
    let pk_arr: [u8; 32] = pk_bytes.try_into().map_err(|_| "Invalid public key length".to_string())?;
    let verifying_key = ed25519_dalek::VerifyingKey::from_bytes(&pk_arr).map_err(|e| e.to_string())?;

    let ns_b58 = bs58::encode(&cap.namespace).into_string();
    let payload = format!("{}:{}:{}:{:?}", cap.delegator, cap.delegatee, ns_b58, cap.access_level);
    
    let sig_arr: [u8; 64] = cap.signature.clone().try_into().map_err(|_| "Invalid signature length".to_string())?;
    let signature = ed25519_dalek::Signature::from_bytes(&sig_arr);

    use ed25519_dalek::Verifier;
    match verifying_key.verify(payload.as_bytes(), &signature) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

pub async fn get_capabilities_for_namespace(namespace_id: String) -> std::collections::HashMap<String, String> {
    let namespace = exotalk_core::protocol_internal::derive_namespace(&namespace_id);
    let store = exotalk_core::network_internal::CAPABILITY_STORE.read().await;
    let mut res = std::collections::HashMap::new();
    if let Some(map) = store.get(&namespace) {
        for (did, level) in map.iter() {
            res.insert(did.clone(), format!("{:?}", level));
        }
    }
    res
}
