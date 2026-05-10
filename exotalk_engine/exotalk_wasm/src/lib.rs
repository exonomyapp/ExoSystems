use wasm_bindgen::prelude::*;
use web_sys::{console, RtcPeerConnection, RtcConfiguration};
use js_sys::Object;

// ============================================================================
// ExoTalk Wasm Engine (Sovereign Session)
//
// 🧠 EDUCATIONAL CONTEXT:
// This module provides the WebAssembly (Wasm) bindings for the ExoTalk engine.
// Wasm allows us to run near-native Rust code inside the browser's sandbox.
// This is critical for maintaining "Sovereign Identity" because the heavy 
// cryptographic work (Ed25519 key generation) happens in Rust, but can be 
// called directly from the Javascript frontend.
//
// 🏗️ TECHNOLOGY STACK:
// - wasm-bindgen: Facilitates high-level interactions between Rust and JS.
// - web-sys: Provides raw bindings to Browser APIs (WebRTC, Console, DOM).
// ============================================================================

#[wasm_bindgen(start)]
pub fn main() -> Result<(), JsValue> {
    // 💡 PATTERN: The "Panic Hook"
    // Rust's default panic message goes to stderr. In the browser, that doesn't 
    // exist. We use `console_error_panic_hook` to redirect Rust panics to the
    // browser's Developer Console so junior devs can debug Wasm crashes.
    console_error_panic_hook::set_once();
    console::log_1(&"Sovereign Wasm Engine 0.1.0 (Demo Mode) Initialized.".into());
    Ok(())
}

/// Represents an active session for a user within the browser environment.
/// 
/// 💡 CONCEPT: The Sovereign Session
/// In the Exosystem, a session is not a "login cookie" from a server. It is 
/// a local-first instantiation of a P2P identity. The browser owns the keys, 
/// and this struct manages the direct connections to other peers.
#[wasm_bindgen]
pub struct SovereignSession {
    /// The user's handle (e.g., "DemoUser")
    handle: String,
    /// The WebRTC PeerConnection instance used to communicate with the mesh.
    /// We use an `Option` because the connection is initialized asynchronously.
    peer_connection: Option<RtcPeerConnection>,
}

#[wasm_bindgen]
impl SovereignSession {
    /// Constructs a new Sovereign Session.
    /// This constructor is called directly from the Javascript frontend:
    /// `const session = new SovereignSession("Alice");`
    #[wasm_bindgen(constructor)]
    pub fn new(handle: String) -> SovereignSession {
        SovereignSession {
            handle,
            peer_connection: None,
        }
    }

    /// Returns the handle associated with this session.
    pub fn get_handle(&self) -> String {
        self.handle.clone()
    }

    /// Synthesizes a Decentralized Identifier (DID) locally.
    /// 
    /// 🛡️ SOVEREIGNTY NOTE:
    /// In the "Solid Identity" standard, identities are synthesized (built) 
    /// rather than "requested." By generating the DID locally, we ensure 
    /// that no central authority can revoke or track the initial birth 
    /// of an identity.
    pub fn synthesize_did(&self) -> String {
        // 🛡️ SOVEREIGNTY: We generate a real Ed25519 keypair directly inside
        // the browser sandbox. The private key never leaves this Wasm instance.
        use ed25519_dalek::SigningKey;
        use rand::rngs::OsRng;
        let signing_key = SigningKey::generate(&mut OsRng);
        let public_key_bytes = signing_key.verifying_key().to_bytes();
        let public_b58 = bs58::encode(public_key_bytes).into_string();
        format!("did:peer:{}", public_b58)
    }

    /// Initiates a connection to the Sovereign Mesh.
    /// 
    /// 💡 LIFECYCLE: The WebRTC Handshake
    /// 1. STUN: Browser discovers its own public IP/Port.
    /// 2. SIGNALING: Browser sends an "Offer" (SDP) to the relay.
    /// 3. ANSWER: Browser receives an "Answer" (SDP) from a peer.
    /// 4. P2P: Direct data channel is established; signaling relay is bypassed.
    pub async fn connect_to_mesh(&mut self, signal_url: &str) -> Result<String, JsValue> {
        console::log_1(&format!("Initializing WebRTC Handshake via {}...", signal_url).into());
        
        // 🔧 CONFIGURATION:
        // We use public Google STUN servers to "hole-punch" through standard home routers (NAT).
        let mut config = RtcConfiguration::new();
        let ice_servers = js_sys::Array::new();
        
        let stun_server = Object::new();
        js_sys::Reflect::set(&stun_server, &"urls".into(), &"stun:stun.l.google.com:19302".into())?;
        ice_servers.push(&stun_server);
        
        config.ice_servers(&ice_servers);
        
        // Initialize the WebRTC connection object using browser-native APIs.
        let pc = RtcPeerConnection::new_with_configuration(&config)?;
        self.peer_connection = Some(pc);
        
        // 🚧 FUTURE WORK:
        // The actual signaling logic (creating offers, sending via WebSocket/HTTP,
        // and handling answers) will be implemented in subsequent phases.
        // This is where we will use `web_sys::fetch` to talk to the Python relay.
        Ok("Mesh Handshake Initiated".into())
    }
}
