// =============================================================================
// willow.rs — Sovereign Identity & Data Engine
// =============================================================================
//
// Hello! This is the "brain" of the ExoTalk backend. It handles everything
// from generating your private keys to managing your message history.
//
// 💡 MENTOR TIP: All functions here are `async`. This is because they often 
// need to wait for the "Hard Drive" (disk) or "Network" (gossip). If they 
// weren't async, your phone would freeze every time you sent a message!
//
// Main Responsibilities:
//   1. Identity Vault — Your cryptographically unique self (did:peer).
//   2. Identity Proofs — How you prove to others who you are.
//   3. OAuth Bindings — Optional "Inward Recovery" anchors.
//   4. Conversations — Your private or group chat channels.
//
// These functions are called by Flutter using the `flutter_rust_bridge`.
// =============================================================================

use tokio::sync::RwLock;
use serde::{Serialize, Deserialize};
use once_cell::sync::Lazy;
use ed25519_dalek::{SigningKey, VerifyingKey, Signer, Verifier};
use rand::rngs::OsRng;


/// An independently-verified link between a did:peer and a public URL.
#[derive(Clone, Debug, Serialize, Deserialize, Default)]
pub struct VerifiedLink {
    pub platform_label: String, // User-defined: "GitHub", "Mastodon", "My Blog"
    pub url: String,
    pub is_verified: bool,
    pub verified_at_ms: i64,
}

/// An archived name record kept when the user renames themselves.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct NameRecord {
    pub name: String,
    pub proof_string: String,           // The proof that was valid for this name
    pub verified_links: Vec<VerifiedLink>,
    pub active_from_ms: i64,
    pub retired_at_ms: i64,
    pub change_certificate: String,     // ed25519 sig: "name-change:from=X:to=Y:at=T"
}

/// An OAuth account linked as a secondary sign-in method.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct OAuthLink {
    pub provider: String,       // "github", "google", "discord", etc.
    pub display_name: String,   // "@alice on GitHub", "alice@gmail.com"
    pub sub: String,            // Stable provider-assigned unique user ID
    pub binding_proof: String,  // ed25519 sig: "oauth-link:provider=X:sub=Y:did=Z:at=T"
    pub linked_at_ms: i64,
}

// 🧠 Educational Context: The Identity Vault
/// Represents a loaded Node Identity (Keypair).
/// This structure is the "Legislative Seal" of the user's presence in the mesh.
/// It contains the local root secret (ed25519) from which all sub-capabilities 
/// and message signatures are derived.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct IdentityVault {
    pub did: String,
    pub secret: String,          // Base58 encoded local root secret
    pub display_name: String,
    pub avatar_url: String,
    #[serde(default)]
    pub proof_string: String,    // Canonical proof for current display_name
    #[serde(default)]
    pub verified_links: Vec<VerifiedLink>,
    #[serde(default)]
    pub oauth_links: Vec<OAuthLink>,
    #[serde(default)]
    pub name_history: Vec<NameRecord>,
    #[serde(default = "default_true")]
    pub ingress_enabled: bool,
    #[serde(default = "default_true")]
    pub egress_enabled: bool,
}

fn default_true() -> bool { true }

/// Represents a User in the peer-to-peer network
pub struct UserIdentity {
    pub did: String,
    pub alias: String,
}



/// Core device settings and manifest of all local profiles.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DeviceManifest {
    pub tenancy_mode: String, // "Isolated" or "Multiplexed"
    pub profiles: Vec<ProfileRecord>,
    #[serde(default)]
    pub associated_conscia_id: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ProfileRecord {
    pub did: String,
    pub display_name: String,
    pub avatar_url: String,
    #[serde(default)]
    pub oauth_subs: Vec<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ProfileMetadata {
    pub did: String,
    pub display_name: String,
    pub avatar_url: String,
    pub last_active: i64,
    #[serde(default)]
    pub oauth_subs: Vec<String>, // Format: "provider:sub"
}

// Store the active node identity
static ACTIVE_IDENTITY: Lazy<RwLock<Option<IdentityVault>>> = Lazy::new(|| RwLock::new(None));

pub(crate) async fn get_active_did_internal() -> Option<String> {
    ACTIVE_IDENTITY.read().await.as_ref().map(|v| v.did.clone())
}

// --- PERSISTENCE HELPERS ---
async fn storage_path(filename: &str) -> std::path::PathBuf {
    let mut p = std::path::PathBuf::from("exotalk_storage");
    let active_identity = { ACTIVE_IDENTITY.read().await.clone() };
    if let Some(vault) = active_identity {
        p.push("profiles");
        p.push(vault.did.replace(":", "_"));
    }
    let _ = std::fs::create_dir_all(&p);
    p.push(filename);
    p
}



pub async fn get_device_manifest() -> DeviceManifest {
    let path = std::path::PathBuf::from("exotalk_storage").join("device_manifest.json");
    let mut manifest = if let Ok(data) = std::fs::read_to_string(&path) {
        serde_json::from_str::<DeviceManifest>(&data).unwrap_or(DeviceManifest {
            tenancy_mode: "Isolated".to_string(),
            profiles: Vec::new(),
            associated_conscia_id: None,
        })
    } else {
        DeviceManifest {
            tenancy_mode: "Isolated".to_string(),
            profiles: Vec::new(),
            associated_conscia_id: None,
        }
    };

    // Heal the manifest if it's missing profiles or has stale names
    let mut changed = false;
    let profiles_dir = std::path::PathBuf::from("exotalk_storage").join("profiles");
    if let Ok(entries) = std::fs::read_dir(profiles_dir) {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                let id_path = entry.path().join("identity.json");
                if let Ok(data) = std::fs::read_to_string(id_path) {
                    if let Ok(vault) = serde_json::from_str::<IdentityVault>(&data) {
                        // Check if manifest matches this vault
                        if let Some(record) = manifest.profiles.iter_mut().find(|p| p.did == vault.did) {
                            if record.display_name != vault.display_name || record.avatar_url != vault.avatar_url {
                                record.display_name = vault.display_name;
                                record.avatar_url = vault.avatar_url;
                                changed = true;
                            }
                        } else {
                            // Missing from manifest entirely
                            manifest.profiles.push(ProfileRecord {
                                did: vault.did,
                                display_name: vault.display_name,
                                avatar_url: vault.avatar_url,
                                oauth_subs: vec![],
                            });
                            changed = true;
                        }
                    }
                }
            }
        }
    }

    if changed {
        save_device_manifest(manifest.clone()).await;
    }



    manifest
}

pub async fn save_device_manifest(manifest: DeviceManifest) {
    let path = std::path::PathBuf::from("exotalk_storage").join("device_manifest.json");
    if let Ok(data) = serde_json::to_string_pretty(&manifest) {
        let _ = std::fs::write(path, data);
    }
}

async fn update_device_manifest(did: &str, display_name: &str, avatar_url: &str) {
    let mut manifest = get_device_manifest().await;
    if let Some(profile) = manifest.profiles.iter_mut().find(|p| p.did == did) {
        profile.display_name = display_name.to_string();
        profile.avatar_url = avatar_url.to_string();
    } else {
        manifest.profiles.push(ProfileRecord {
            did: did.to_string(),
            display_name: display_name.to_string(),
            avatar_url: avatar_url.to_string(),
            oauth_subs: vec![],
        });
    }
    save_device_manifest(manifest).await;
}

/// Closes the active databases, unloads identity, and signals network shutdown
pub async fn sign_out_profile() {
    {
        let mut active = ACTIVE_IDENTITY.write().await;
        *active = None;
    }

}

/// Sets the given DID as the active profile and boots up its P2P network node.
pub async fn switch_active_profile(did: String) -> Result<bool, String> {
    if let Some(active) = ACTIVE_IDENTITY.read().await.clone() {
        if active.did == did {
            return Ok(true);
        }
    }

    println!("Switching active profile to: {}", did);
    sign_out_profile().await;
    println!("Previous profile signed out. Preparing new profile...");
    
    // Temporarily fake ACTIVE_IDENTITY to allow storage_path to resolve to this DID
    {
        let mut active = ACTIVE_IDENTITY.write().await;
        *active = Some(IdentityVault {
            did: did.clone(),
            secret: "".to_string(), display_name: "".to_string(), avatar_url: "".to_string(),
            proof_string: "".to_string(), verified_links: vec![], oauth_links: vec![], name_history: vec![],
            ingress_enabled: true, egress_enabled: true,
        });
    }

    let identity_path = storage_path("identity.json").await;
    match std::fs::read_to_string(&identity_path) {
        Ok(data) => {
            match serde_json::from_str::<IdentityVault>(&data) {
                Ok(vault) => {
                    {
                        let mut active = ACTIVE_IDENTITY.write().await;
                        *active = Some(vault.clone());
                    }
                    println!("Profile switch successful for: {}", did);
                    return Ok(true);
                }
                Err(e) => {
                    println!("Failed to parse identity JSON: {}", e);
                    sign_out_profile().await;
                    return Err(format!("Parse error: {}", e));
                }
            }
        }
        Err(e) => {
            println!("Failed to read identity.json: {}", e);
        }
    }
    
    // Clear fake active identity if it failed
    sign_out_profile().await;
    Err("Profile not found on disk".to_string())
}

// 🧠 Educational Context: Cryptographic Self-Generation
/// Generates a genuine ed25519 keypair and encodes it into a did:peer identifier.
/// This is the "Big Bang" of a sovereign session. By generating keys 
/// locally on the device's CSPRNG (OsRng), we ensure that no central 
/// authority ever sees the private secret, fulfilling the "Own Your Data" mandate.
pub async fn generate_new_identity() -> IdentityVault {
    // IMPORTANT: Clear any active profile before generating a new one
    sign_out_profile().await;

    let mut csprng = OsRng;
    let signing_key: SigningKey = SigningKey::generate(&mut csprng);
    let public_key: VerifyingKey = signing_key.verifying_key();
    
    let pk_b58 = bs58::encode(public_key.as_bytes()).into_string();
    let sk_b58 = bs58::encode(signing_key.to_bytes()).into_string();
    
    let did = format!("did:peer:2.Vz{}", pk_b58);
    let vault = IdentityVault { 
        did: did.clone(), 
        secret: sk_b58.clone(),
        display_name: "".to_string(),
        avatar_url: "".to_string(),
        proof_string: "".to_string(),
        verified_links: vec![],
        oauth_links: vec![],
        name_history: vec![],
        ingress_enabled: true,
        egress_enabled: true,
    };
    
    // Set active session FIRST so storage_path resolves to the correct isolated folder
    {
        let mut active = ACTIVE_IDENTITY.write().await;
        *active = Some(vault.clone());
    }

    if let Ok(j) = serde_json::to_string(&vault) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }

    // Register with the global manifest
    update_device_manifest(&did, "", "").await;

    vault
}

/// Returns the active node identity. Returns an empty vault if no identity is active.
pub async fn get_active_identity() -> IdentityVault {
    let active = ACTIVE_IDENTITY.read().await;
    if let Some(vault) = active.as_ref() {
        return vault.clone();
    }
    drop(active);
    
    // If no in-memory active identity, try to load the last one from the current storage path
    if let Ok(data) = std::fs::read_to_string(storage_path("identity.json").await) {
        if let Ok(vault) = serde_json::from_str::<IdentityVault>(&data) {
            let mut active = ACTIVE_IDENTITY.write().await;
            *active = Some(vault.clone());
            return vault;
        }
    }
    
    IdentityVault {
        did: "".to_string(),
        display_name: "".to_string(),
        avatar_url: "".to_string(),
        secret: "".to_string(),
        proof_string: "".to_string(),
        verified_links: vec![],
        oauth_links: vec![],
        name_history: vec![],
        ingress_enabled: true,
        egress_enabled: true,
    }
}

pub async fn update_active_profile(name: String, avatar: String) -> IdentityVault {
    let mut vault = get_active_identity().await;
    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;

    if vault.display_name != name && !vault.display_name.is_empty() {
        // Sign a name-change certificate
        let change_cert = if let Ok(sk_bytes) = bs58::decode(&vault.secret).into_vec() {
            if let Ok(sk_arr) = sk_bytes.try_into() as Result<[u8; 32], _> {
                let sk = ed25519_dalek::SigningKey::from_bytes(&sk_arr);
                let claim = format!("name-change:from={}:to={}:at={}", vault.display_name, name, now_ms);
                let sig = sk.sign(claim.as_bytes());
                format!("{}:sig={}", claim, bs58::encode(sig.to_bytes()).into_string())
            } else { String::new() }
        } else { String::new() };

        // Archive the current name into history
        let record = NameRecord {
            name: vault.display_name.clone(),
            proof_string: vault.proof_string.clone(),
            verified_links: vault.verified_links.clone(),
            active_from_ms: 0, // TODO(identity): Track vault.activated_at_ms to populate this correctly
            retired_at_ms: now_ms,
            change_certificate: change_cert,
        };
        vault.name_history.push(record);
        vault.proof_string = "".to_string();
        vault.verified_links = vec![];
    }

    vault.display_name = name.clone();
    vault.avatar_url = avatar.clone();
    
    if let Ok(j) = serde_json::to_string(&vault) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }
    
    // Also update the global manifest so the identity picker shows the new name
    update_device_manifest(&vault.did, &name, &avatar).await;

    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

/// Generates a signed proof string linking the display name to the did:peer key.
/// Format (Legacy): exotalk-proof:v1:did={DID}:name={NAME}:sig={BASE58_SIG}
/// Format (Full Compact): etp1:{PUBKEY_B58}.{SIG_B58}
/// Format (Minimal): ets1:{SIG_B58}
pub async fn generate_verification_proof(format: String) -> Result<String, String> {
    let vault = get_active_identity().await;
    if vault.display_name.is_empty() {
        return Err("Set a display name before generating a verification proof.".to_string());
    }

    let sk_bytes = bs58::decode(&vault.secret).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Invalid secret key length".to_string())?;
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&sk_arr);

    let claim = format!("exotalk-proof:v1:did={}:name={}", vault.did, vault.display_name);
    let signature = signing_key.sign(claim.as_bytes());
    let sig_b58 = bs58::encode(signature.to_bytes()).into_string();

    let proof = generate_proof_string_for_format(&format, &vault.did, &vault.display_name, &sig_b58, &claim);

    let mut updated = vault;
    updated.proof_string = proof.clone();
    if let Ok(j) = serde_json::to_string(&updated) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(updated);

    Ok(proof)
}

/// Evaluates all available proof formats and returns the best one that fits within max_chars.
pub async fn generate_best_proof(max_chars: usize) -> Result<String, String> {
    let vault = get_active_identity().await;
    if vault.display_name.is_empty() {
        return Err("Set a display name before generating a verification proof.".to_string());
    }

    let sk_bytes = bs58::decode(&vault.secret).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Invalid secret key length".to_string())?;
    let signing_key = ed25519_dalek::SigningKey::from_bytes(&sk_arr);

    let claim = format!("exotalk-proof:v1:did={}:name={}", vault.did, vault.display_name);
    let signature = signing_key.sign(claim.as_bytes());
    let sig_b58 = bs58::encode(signature.to_bytes()).into_string();

    // Check formats in order of preference (most verbose first)
    let formats = vec!["legacy", "full", "compact"];
    let mut best_proof = String::new();

    for fmt in formats {
        let p = generate_proof_string_for_format(fmt, &vault.did, &vault.display_name, &sig_b58, &claim);
        if p.len() <= max_chars {
            best_proof = p;
            break;
        }
        best_proof = p; // fall back to the last one (compact) if none fit
    }

    let mut updated = vault;
    updated.proof_string = best_proof.clone();
    if let Ok(j) = serde_json::to_string(&updated) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(updated);

    Ok(best_proof)
}

fn generate_proof_string_for_format(format: &str, did: &str, _name: &str, sig_b58: &str, claim: &str) -> String {
    match format {
        "compact" => format!("ets1:{}", sig_b58),
        "full" => {
            let pk_b58 = did.strip_prefix("did:peer:2.Vz").unwrap_or(did);
            format!("etp1:{}.{}", pk_b58, sig_b58)
        },
        _ => format!("{}:sig={}", claim, sig_b58), // legacy
    }
}

/// Verifies any supported ExoTalk proof string locally.
pub fn verify_proof_locally(proof: String) -> bool {
    let vault = match futures_lite::future::block_on(get_active_identity_sync()) {
        Some(v) => v,
        None => return false,
    };

    if proof.starts_with("ets1:") {
        let sig_b58 = &proof[5..];
        return verify_raw_sig(sig_b58, &vault.did, &vault.display_name);
    }
    
    if proof.starts_with("etp1:") {
        let content = &proof[5..];
        let parts: Vec<&str> = content.split('.').collect();
        if parts.len() != 2 { return false; }
        return verify_raw_sig(parts[1], &vault.did, &vault.display_name);
    }

    // Legacy parser
    let sig_marker = ":sig=";
    let sig_pos = match proof.rfind(sig_marker) {
        Some(p) => p,
        None => return false,
    };
    let sig_b58 = &proof[sig_pos + sig_marker.len()..];
    verify_raw_sig(sig_b58, &vault.did, &vault.display_name)
}

fn verify_raw_sig(sig_b58: &str, did: &str, name: &str) -> bool {
    let sig_bytes = match bs58::decode(sig_b58).into_vec() {
        Ok(b) => b,
        Err(_) => return false,
    };
    let sig_arr: [u8; 64] = match sig_bytes.try_into() {
        Ok(a) => a,
        Err(_) => return false,
    };
    let signature = ed25519_dalek::Signature::from_bytes(&sig_arr);

    let pk_b58 = match did.strip_prefix("did:peer:2.Vz") {
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

    let claim = format!("exotalk-proof:v1:did={}:name={}", did, name);
    use ed25519_dalek::Verifier;
    verifying_key.verify(claim.as_bytes(), &signature).is_ok()
}

pub async fn set_ingress_enabled(enabled: bool) -> IdentityVault {
    let mut vault = get_active_identity().await;
    vault.ingress_enabled = enabled;
    if let Ok(j) = serde_json::to_string(&vault) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

pub async fn set_egress_enabled(enabled: bool) -> IdentityVault {
    let mut vault = get_active_identity().await;
    vault.egress_enabled = enabled;
    if let Ok(j) = serde_json::to_string(&vault) {
        let _ = std::fs::write(storage_path("identity.json").await, j);
    }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

async fn get_active_identity_sync() -> Option<IdentityVault> {
    let active = ACTIVE_IDENTITY.read().await;
    active.clone()
}

// --- MULTI-PLATFORM VERIFIED LINKS ---

/// Adds a pending (unverified) link to the vault.
pub async fn add_verification_link(label: String, url: String) -> IdentityVault {
    let mut vault = get_active_identity().await;
    // Don't add duplicates
    if !vault.verified_links.iter().any(|l| l.url == url) {
        vault.verified_links.push(VerifiedLink { platform_label: label, url, is_verified: false, verified_at_ms: 0 });
    }
    if let Ok(j) = serde_json::to_string(&vault) { let _ = std::fs::write(storage_path("identity.json").await, j); }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

/// Marks an existing link by URL as verified or failed after an HTTP check.
pub async fn confirm_verification_link(url: String, verified: bool) -> IdentityVault {
    let mut vault = get_active_identity().await;
    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;
    if let Some(link) = vault.verified_links.iter_mut().find(|l| l.url == url) {
        link.is_verified = verified;
        link.verified_at_ms = if verified { now_ms } else { 0 };
    }
    if let Ok(j) = serde_json::to_string(&vault) { let _ = std::fs::write(storage_path("identity.json").await, j); }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

/// Removes a link by URL.
pub async fn remove_verification_link(url: String) -> IdentityVault {
    let mut vault = get_active_identity().await;
    vault.verified_links.retain(|l| l.url != url);
    if let Ok(j) = serde_json::to_string(&vault) { let _ = std::fs::write(storage_path("identity.json").await, j); }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

/// Renames the display label of a link.
pub async fn update_link_label(url: String, new_label: String) -> IdentityVault {
    let mut vault = get_active_identity().await;
    if let Some(link) = vault.verified_links.iter_mut().find(|l| l.url == url) {
        link.platform_label = new_label;
    }
    if let Ok(j) = serde_json::to_string(&vault) { let _ = std::fs::write(storage_path("identity.json").await, j); }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault.clone());
    vault
}

/// Returns the full name history list.
pub async fn get_name_history() -> Vec<NameRecord> {
    let vault = get_active_identity().await;
    vault.name_history
}

// --- OAUTH LINKS ---

static DB_OAUTH: Lazy<RwLock<Vec<OAuthLink>>> = Lazy::new(|| RwLock::new(Vec::new()));

async fn load_oauth_links() {
    if let Ok(data) = std::fs::read_to_string(storage_path("oauth_links.json").await) {
        if let Ok(parsed) = serde_json::from_str::<Vec<OAuthLink>>(&data) {
            let mut db = DB_OAUTH.write().await;
            *db = parsed;
        }
    }
}

async fn save_oauth_links() {
    if let Ok(j) = serde_json::to_string(&*DB_OAUTH.read().await) {
        let _ = std::fs::write(storage_path("oauth_links.json").await, j);
    }
}

/// Links an OAuth account to the active did:peer by signing a binding proof.
pub async fn add_oauth_link(provider: String, display_name: String, sub: String) -> OAuthLink {
    let vault = get_active_identity().await;
    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;

    let binding_proof = if let Ok(sk_bytes) = bs58::decode(&vault.secret).into_vec() {
        if let Ok(sk_arr) = sk_bytes.try_into() as Result<[u8; 32], _> {
            let sk = ed25519_dalek::SigningKey::from_bytes(&sk_arr);
            let claim = format!("oauth-link:provider={}:sub={}:did={}:at={}", provider, sub, vault.did, now_ms);
            let sig = sk.sign(claim.as_bytes());
            format!("{}:sig={}", claim, bs58::encode(sig.to_bytes()).into_string())
        } else { String::new() }
    } else { String::new() };

    let link = OAuthLink { provider: provider.clone(), display_name, sub, binding_proof, linked_at_ms: now_ms };
    {
        let mut db = DB_OAUTH.write().await;
        db.retain(|l| l.provider != provider); // replace existing
        db.push(link.clone());
    }
    save_oauth_links().await;
    link
}

/// Removes an OAuth link by provider key.
pub async fn remove_oauth_link(provider: String) {
    { let mut db = DB_OAUTH.write().await; db.retain(|l| l.provider != provider); }
    save_oauth_links().await;
}

/// Returns all linked OAuth accounts.
pub async fn get_oauth_links() -> Vec<OAuthLink> {
    load_oauth_links().await;
    DB_OAUTH.read().await.clone()
}

/// Finds the did:peer for a given OAuth provider + sub combination.
/// Returns an empty string if not found.
pub async fn find_did_for_oauth(provider: String, sub: String) -> String {
    load_oauth_links().await;
    let db = DB_OAUTH.read().await;
    if db.iter().any(|l| l.provider == provider && l.sub == sub) {
        get_active_identity().await.did
    } else {
        String::new()
    }
}

// --- CROSS-DEVICE PAIRING ---

/// Generates a short-lived signed pairing token for QR-code device sync.
/// The token encodes: did + timestamp + signature. Expires after 5 minutes.
pub async fn generate_device_pairing_token() -> Result<String, String> {
    let vault = get_active_identity().await;
    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;

    let sk_bytes = bs58::decode(&vault.secret).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Invalid key".to_string())?;
    let sk = ed25519_dalek::SigningKey::from_bytes(&sk_arr);
    let claim = format!("exotalk-pair:did={}:at={}", vault.did, now_ms);
    let sig = sk.sign(claim.as_bytes());
    Ok(format!("{}:sig={}", claim, bs58::encode(sig.to_bytes()).into_string()))
}

/// Verifies a pairing token (checks signature and 5-minute expiry).
pub fn verify_device_pairing_token(token: String) -> bool {
    // Delegate through the same verification engine as proof strings (same format)
    // Additionally check timestamp expiry
    let at_marker = ":at=";
    let sig_marker = ":sig=";
    let at_pos = match token.find(at_marker) { Some(p) => p, None => return false };
    let sig_pos = match token.rfind(sig_marker) { Some(p) => p, None => return false };
    let ts_str = &token[at_pos + at_marker.len()..sig_pos];
    let ts: i64 = match ts_str.parse() { Ok(t) => t, Err(_) => return false };
    let now_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH).unwrap_or_default().as_millis() as i64;
    if now_ms - ts > 5 * 60 * 1000 { return false; } // expired
    verify_proof_locally(token) // re-uses the same signature logic
}

/// Exports the full profile + OAuth links as a JSON string (for cross-device transfer).
/// In a production implementation this would be encrypted; here it is signed.
pub async fn export_profile_bundle() -> Result<String, String> {
    let vault = get_active_identity().await;
    load_oauth_links().await;
    let oauth = DB_OAUTH.read().await.clone();
    let bundle = serde_json::json!({ "vault": vault, "oauth_links": oauth });
    let bundle_str = serde_json::to_string(&bundle).map_err(|e| e.to_string())?;

    let sk_bytes = bs58::decode(&vault.secret).into_vec().map_err(|e| e.to_string())?;
    let sk_arr: [u8; 32] = sk_bytes.try_into().map_err(|_| "Invalid key".to_string())?;
    let sk = ed25519_dalek::SigningKey::from_bytes(&sk_arr);
    let sig = sk.sign(bundle_str.as_bytes());
    let sig_b58 = bs58::encode(sig.to_bytes()).into_string();
    Ok(format!("{}.{}", { use base64::Engine; base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(&bundle_str) }, sig_b58))
}

/// Imports a profile bundle from another device (verifies did:peer signature first).
pub async fn import_profile_bundle(bundle: String) -> bool {
    use base64::Engine;
    let parts: Vec<&str> = bundle.rsplitn(2, '.').collect();
    if parts.len() != 2 { return false; }
    let sig_b58 = parts[0];
    let payload_b64 = parts[1];
    let payload_bytes = match base64::engine::general_purpose::URL_SAFE_NO_PAD.decode(payload_b64) {
        Ok(b) => b, Err(_) => return false
    };
    let payload_str = match std::str::from_utf8(&payload_bytes) {
        Ok(s) => s, Err(_) => return false
    };
    let bundle_val: serde_json::Value = match serde_json::from_str(payload_str) {
        Ok(v) => v, Err(_) => return false
    };
    let vault: IdentityVault = match serde_json::from_value(bundle_val["vault"].clone()) {
        Ok(v) => v, Err(_) => return false
    };
    // Verify signature using the embedded DID public key
    let pk_b58 = match vault.did.strip_prefix("did:peer:2.Vz") {
        Some(k) => k, None => return false
    };
    let pk_bytes = match bs58::decode(pk_b58).into_vec() { Ok(b) => b, Err(_) => return false };
    let pk_arr: [u8; 32] = match pk_bytes.try_into() { Ok(a) => a, Err(_) => return false };
    let vk = match ed25519_dalek::VerifyingKey::from_bytes(&pk_arr) { Ok(k) => k, Err(_) => return false };
    let sig_bytes = match bs58::decode(sig_b58).into_vec() { Ok(b) => b, Err(_) => return false };
    let sig = match ed25519_dalek::Signature::from_slice(&sig_bytes) { Ok(s) => s, Err(_) => return false };
    use ed25519_dalek::Verifier;
    if vk.verify(payload_bytes.as_slice(), &sig).is_err() { return false; }
    // Write to disk
    if let Ok(j) = serde_json::to_string(&vault) { let _ = std::fs::write(storage_path("identity.json").await, j); }
    if let Ok(oauth) = serde_json::from_value::<Vec<OAuthLink>>(bundle_val["oauth_links"].clone()) {
        if let Ok(j) = serde_json::to_string(&oauth) { let _ = std::fs::write(storage_path("oauth_links.json").await, j); }
        let mut db = DB_OAUTH.write().await;
        *db = oauth;
    }
    let mut active = ACTIVE_IDENTITY.write().await;
    *active = Some(vault);
    true
}


pub async fn find_profile_by_oauth(provider: String, sub: String) -> Option<String> {
    let manifest = get_device_manifest().await;
    let target = format!("{}:{}", provider, sub);
    for profile in manifest.profiles {
        if profile.oauth_subs.contains(&target) {
            return Some(profile.did);
        }
    }
    None
}

pub async fn create_profile_from_oauth(provider: String, sub: String, name: String, avatar: String) -> Result<String, String> {
    // 1. Generate new identity
    let vault = generate_new_identity().await;
    
    // 2. Update vault with OAuth info
    {
        let mut active = ACTIVE_IDENTITY.write().await;
        if let Some(ref mut v) = *active {
            v.display_name = name.clone();
            v.avatar_url = avatar.clone();
            v.oauth_links.push(OAuthLink {
                provider: provider.clone(),
                display_name: name.clone(),
                sub: sub.clone(),
                binding_proof: "".to_string(), // In a real app, we'd sign a proof here
                linked_at_ms: chrono::Utc::now().timestamp_millis(),
            });
            
            // Save updated vault
            if let Ok(j) = serde_json::to_string(&v) {
                let _ = std::fs::write(storage_path("identity.json").await, j);
            }
        }
    }
    
    // 3. Update manifest with oauth_sub for discovery
    let mut manifest = get_device_manifest().await;
    let target = format!("{}:{}", provider, sub);
    for profile in &mut manifest.profiles {
        if profile.did == vault.did {
            profile.display_name = name.clone();
            profile.avatar_url = avatar.clone();
            profile.oauth_subs.push(target.clone());
        }
    }
    save_device_manifest(manifest).await;
    
    Ok(vault.did)
}

pub async fn link_oauth_to_existing_profile(did: String, provider: String, sub: String) -> Result<bool, String> {
    // 1. Switch to the profile to ensure we can edit its vault
    if !switch_active_profile(did.clone()).await? {
        return Err("Could not switch to profile".to_string());
    }
    
    // 2. Add OAuth link to vault
    {
        let mut active = ACTIVE_IDENTITY.write().await;
        if let Some(ref mut v) = *active {
            let target = format!("{}:{}", provider, sub);
            if !v.oauth_links.iter().any(|l| format!("{}:{}", l.provider, l.sub) == target) {
                v.oauth_links.push(OAuthLink {
                    provider: provider.clone(),
                    display_name: format!("{} account", provider),
                    sub: sub.clone(),
                    binding_proof: "".to_string(),
                    linked_at_ms: chrono::Utc::now().timestamp_millis(),
                });
                
                // Save updated vault
                if let Ok(j) = serde_json::to_string(&v) {
                    let _ = std::fs::write(storage_path("identity.json").await, j);
                }
            }
        }
    }
    
    // 3. Update manifest for future discovery
    let mut manifest = get_device_manifest().await;
    let target = format!("{}:{}", provider, sub);
    for profile in &mut manifest.profiles {
        if profile.did == did {
            if !profile.oauth_subs.contains(&target) {
                profile.oauth_subs.push(target.clone());
            }
        }
    }
    save_device_manifest(manifest).await;
    
    Ok(true)
}
