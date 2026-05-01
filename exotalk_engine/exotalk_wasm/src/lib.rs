use wasm_bindgen::prelude::*;
use web_sys::{console, RtcPeerConnection, RtcConfiguration};
use js_sys::Object;

// ============================================================================
// ExoTalk Wasm Engine (Sovereign Session)
//
// This module provides the WebAssembly bindings for the ExoTalk engine.
// It allows the browser to instantiate a "Sovereign Session" which represents
// a P2P identity and manages the WebRTC connectivity required to join the
// ExoTalk mesh without relying on a centralized server for data transport.
// ============================================================================

#[wasm_bindgen(start)]
pub fn main() -> Result<(), JsValue> {
    // Sets up a panic hook to route Rust panics to the browser console.
    // This is crucial for debugging Wasm modules in the browser.
    console_error_panic_hook::set_once();
    console::log_1(&"Sovereign Wasm Engine 0.1.0 (Demo Mode) Initialized.".into());
    Ok(())
}

/// Represents an active session for a user within the browser environment.
/// This struct is exported to Javascript via `#[wasm_bindgen]`.
#[wasm_bindgen]
pub struct SovereignSession {
    /// The user's handle (e.g., "DemoUser")
    handle: String,
    /// The WebRTC PeerConnection instance used to communicate with the mesh
    peer_connection: Option<RtcPeerConnection>,
}

#[wasm_bindgen]
impl SovereignSession {
    /// Constructs a new Sovereign Session.
    /// This constructor is called directly from the Javascript frontend.
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
    /// In a production environment, this would involve generating an Ed25519
    /// keypair and formatting the public key according to the `did:peer` spec.
    /// For the demo, we generate a deterministic placeholder.
    pub fn synthesize_did(&self) -> String {
        format!("did:peer:2.Ez6LS...{}...{}", &self.handle, "demo")
    }

    /// Initiates a connection to the Sovereign Mesh.
    /// 
    /// This method sets up the initial WebRTC configuration and prepares the
    /// `RtcPeerConnection`. It expects a `signal_url` which points to the
    /// lightweight Python signaling relay (e.g., the zrok tunnel) used to
    /// exchange SDP offers/answers.
    pub async fn connect_to_mesh(&mut self, signal_url: &str) -> Result<String, JsValue> {
        console::log_1(&format!("Initializing WebRTC Handshake via {}...", signal_url).into());
        
        // Configure WebRTC with public STUN servers.
        // STUN is necessary for the browser to discover its public IP address
        // so it can establish direct P2P connections (hole punching).
        let mut config = RtcConfiguration::new();
        let ice_servers = js_sys::Array::new();
        
        let stun_server = Object::new();
        js_sys::Reflect::set(&stun_server, &"urls".into(), &"stun:stun.l.google.com:19302".into())?;
        ice_servers.push(&stun_server);
        
        config.ice_servers(&ice_servers);
        
        // Initialize the WebRTC connection object.
        let pc = RtcPeerConnection::new_with_configuration(&config)?;
        self.peer_connection = Some(pc);
        
        // Note: The actual signaling logic (creating offers, sending via WebSocket/HTTP,
        // and handling answers) will be implemented in subsequent phases.
        Ok("Mesh Handshake Initiated".into())
    }
}
