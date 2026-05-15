use wasm_bindgen::prelude::*;
use web_sys::{console, RtcPeerConnection, RtcConfiguration};
use js_sys::Object;

// ============================================================================
// ExoTalk Wasm Engine
//
// This module provides the WebAssembly (Wasm) bindings for the ExoTalk engine.
// Wasm allows running Rust code inside the browser environment.
// This handles cryptographic operations (Ed25519 key generation) in Rust,
// which is called from the Javascript frontend.
//
// Technology Stack:
// - wasm-bindgen: Facilitates interactions between Rust and JS.
// - web-sys: Provides bindings to Browser APIs (WebRTC, Console, DOM).
// ============================================================================

#[wasm_bindgen(start)]
pub fn main() -> Result<(), JsValue> {
    console_error_panic_hook::set_once();
    console::log_1(&"Wasm Engine 0.1.0 Initialized.".into());
    Ok(())
}

/// Represents an active session for a user within the browser environment.
/// 
/// A session is a local-first instantiation of a P2P identity. 
/// The browser manages the keys, and this struct handles the connections 
/// to other peers.
#[wasm_bindgen]
pub struct Session {
    /// The user's handle (e.g., "DemoUser")
    handle: String,
    /// The WebRTC PeerConnection instance used to communicate with the mesh.
    peer_connection: Option<RtcPeerConnection>,
}

#[wasm_bindgen]
impl Session {
    /// Constructs a new Session.
    #[wasm_bindgen(constructor)]
    pub fn new(handle: String) -> Session {
        Session {
            handle,
            peer_connection: None,
        }
    }

    /// Returns the handle associated with this session.
    pub fn get_handle(&self) -> String {
        self.handle.clone()
    }

    /// Generates a Decentralized Identifier (DID) locally.
    pub fn generate_did(&self) -> String {
        // Generate an Ed25519 keypair inside the browser sandbox. 
        // The private key remains within this Wasm instance.
        use ed25519_dalek::SigningKey;
        use rand::rngs::OsRng;
        let signing_key = SigningKey::generate(&mut OsRng);
        let public_key_bytes = signing_key.verifying_key().to_bytes();
        let public_b58 = bs58::encode(public_key_bytes).into_string();
        format!("did:peer:{}", public_b58)
    }

    /// Initiates a connection to the mesh.
    /// 
    /// WebRTC Handshake Lifecycle:
    /// 1. STUN: Browser discovers its public IP/Port.
    /// 2. SIGNALING: Browser sends an "Offer" (SDP) to the relay.
    /// 3. ANSWER: Browser receives an "Answer" (SDP) from a peer.
    /// 4. P2P: Direct data channel is established.
    pub async fn connect_to_mesh(&mut self, signal_url: &str) -> Result<String, JsValue> {
        console::log_1(&format!("Initializing WebRTC Handshake via {}...", signal_url).into());
        
        let mut config = RtcConfiguration::new();
        let ice_servers = js_sys::Array::new();
        
        let stun_server = Object::new();
        js_sys::Reflect::set(&stun_server, &"urls".into(), &"stun:stun.l.google.com:19302".into())?;
        ice_servers.push(&stun_server);
        
        config.ice_servers(&ice_servers);
        
        // Initialize the WebRTC connection object using browser-native APIs.
        let pc = RtcPeerConnection::new_with_configuration(&config)?;
        self.peer_connection = Some(pc);
        
        Ok("Mesh Handshake Initiated".into())
    }
}
