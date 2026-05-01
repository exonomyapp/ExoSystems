// =============================================================================
// protocol_internal.rs — Willow Protocol Helpers
// =============================================================================
//
// Welcome to the core plumbing! This module helps us translate high-level
// concepts (like "Conversation Titles" or "User DIDs") into the 32-byte 
// numbers that the Willow protocol needs to organize data.
// 
// 💡 MENTOR TIP: Willow uses deterministic hashing (BLAKE3). This ensures 
// that any peer in the world can calculate the exact same "Namespace ID" 
// for a chat conversation just by knowing its unique ID string.
//
// These functions are NOT exposed to Flutter directly. They're internal
// helpers used by our Rust network engine.
// =============================================================================

use serde::{Serialize, Deserialize};

/// ExoTalk message payload structure (serialized to bytes for Willow blob storage).
/// This is the canonical wire format for chat messages.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct MessagePayloadV1 {
    pub content: String,
    pub timestamp_ms: i64,
}

/// Helper to derive a 32-byte Namespace ID from a conversation string
pub fn derive_namespace(convo_id: &str) -> [u8; 32] {
    let hash = blake3::hash(convo_id.as_bytes());
    *hash.as_bytes()
}

/// Helper to derive a 32-byte Author ID from a DID string
pub fn derive_author(did: &str) -> [u8; 32] {
    // In did:peer:2, the key is already base58 encoded. 
    // We'll take the hash of the DID to ensure we always have 32 bytes for the Subspace.
    let hash = blake3::hash(did.as_bytes());
    *hash.as_bytes()
}

pub fn _create_path(msg_id: &str) -> Vec<Vec<u8>> {
    vec![
        b"exotalk".to_vec(),
        b"chat".to_vec(),
        b"v1".to_vec(),
        msg_id.as_bytes().to_vec(),
    ]
}

pub fn encode_message(content: &str, timestamp: i64) -> Result<Vec<u8>, String> {
    let payload = MessagePayloadV1 {
        content: content.to_string(),
        timestamp_ms: timestamp,
    };
    serde_json::to_vec(&payload).map_err(|e| format!("Serialization error: {}", e))
}

pub fn _decode_message(bytes: &[u8]) -> Result<MessagePayloadV1, String> {
    serde_json::from_slice(bytes).map_err(|e| format!("Deserialization error: {}", e))
}

/// Meadowcap Permission Definitions
/// 💡 MENTOR TIP: This enum defines what a user is allowed to do.
/// - Read: Can see messages but can't speak.
/// - Write: Can send messages.
/// - Admin: Can "delegate" their power to others, creating a chain of trust!
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Eq)]
pub enum PermissionLevel {
    Read,
    Write,
    Admin, 
}

/// A Meadowcap Capability token proving access rights.
/// 💡 MENTOR TIP: Think of this as a "Digital VIP Badge". 
/// It's a small JSON object signed by someone who is already an Admin.
/// Peers only listen to people who can produce a valid badge for the conversation.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Capability {
    pub delegator: String,          // The did:peer granting the access
    pub delegatee: String,          // The did:peer receiving the access
    pub namespace: [u8; 32],        // The conversation hash this badge applies to
    pub access_level: PermissionLevel,
    pub signature: Vec<u8>,         // The cryptographic "stamp" from the Delegator
}

impl Capability {
    /// Mathematical verification of the token using Ed25519.
    pub fn verify(&self) -> bool {
        // Step 1: Extract the "Public Key" from the delegator's DID name.
        // We look for the base58 string after "did:peer:2.Vz".
        let pk_b58 = match self.delegator.strip_prefix("did:peer:2.Vz") {
            Some(s) => s,
            None => return false,
        };
        
        let pk_bytes = match bs58::decode(pk_b58).into_vec() {
            Ok(b) => b,
            Err(_) => return false,
        };
        
        let pk_arr: [u8; 32] = match pk_bytes.try_into() {
            Ok(a) => a,
            Err(_) => return false,
        };
        
        let verifying_key = match ed25519_dalek::VerifyingKey::from_bytes(&pk_arr) {
            Ok(k) => k,
            Err(_) => return false,
        };

        let ns_b58 = bs58::encode(&self.namespace).into_string();
        let payload = format!("{}:{}:{}:{:?}", self.delegator, self.delegatee, ns_b58, self.access_level);
        
        let sig_arr: [u8; 64] = match self.signature.clone().try_into() {
            Ok(a) => a,
            Err(_) => return false,
        };
        
        let signature = ed25519_dalek::Signature::from_bytes(&sig_arr);

        use ed25519_dalek::Verifier;
        verifying_key.verify(payload.as_bytes(), &signature).is_ok()
    }
}

/// A package broadcast upon connecting to a gossip mesh to prove identity
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct IdentityBundle {
    pub did: String,                // did:peer:2.Vz...
    pub display_name: String,       // The raw display name
    pub proof_string: String,       // The `etp1:...` signature linking the display name to the DID
}

/// A tombstone representing a revoked capability
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct RevocationTombstone {
    pub delegator: String,
    pub delegatee: String,
    pub namespace: [u8; 32],
    pub signature: Vec<u8>,         // Deposited by the revoker (delegator or higher)
}
/// A request from a peer to join a conversation or mesh.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct JoinRequest {
    pub node_id: String,
    pub timestamp_ms: i64,
}

/// Helper to sign and create a new capability token.
pub fn delegate_capability(
    delegator_did: &str,
    delegatee_did: &str,
    namespace: [u8; 32],
    level: PermissionLevel,
    secret_key_b58: &str,
) -> Result<Capability, String> {
    let sk_bytes = bs58::decode(secret_key_b58).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Secret key length mismatch".to_string())?;
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&sk_arr);

    let ns_b58 = bs58::encode(&namespace).into_string();
    let payload = format!("{}:{}:{}:{:?}", delegator_did, delegatee_did, ns_b58, level);
    
    use ed25519_dalek::Signer;
    let signature = signing_key.sign(payload.as_bytes()).to_bytes().to_vec();

    Ok(Capability {
        delegator: delegator_did.to_string(),
        delegatee: delegatee_did.to_string(),
        namespace,
        access_level: level,
        signature,
    })
}
