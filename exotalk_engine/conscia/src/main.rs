// 🧠 EDUCATIONAL CONTEXT: The Conscia Beacon acts as a sovereign entry point into the mesh.
// It bridges the gap between raw P2P protocols (Iroh) and human-readable interfaces (Web).
// By serving an Axum-based HTTP API alongside the P2P engine, we enable "Remote Observability"
// where any authorized UI (like the Exotech Bridge) can interrogate the node state.
// =============================================================================


use axum::{
    extract::Query,
    http::StatusCode,
    response::{Html, IntoResponse, sse::{Event, Sse}},
    routing::{get, post},
    Json, Router,
};
use clap::{Parser, Subcommand};
use exotalk_core::network_internal;
use futures_util::stream::Stream;
use inquire::{Select, Text as InquireText};
use once_cell::sync::Lazy;
use rust_embed::RustEmbed;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::convert::Infallible;
use std::net::SocketAddr;
use std::path::PathBuf;
use tokio::runtime::Runtime;
use tokio_stream::wrappers::BroadcastStream;
use tokio_stream::StreamExt;
use tracing_core::{Event as TracingEvent, Subscriber};
use tracing_subscriber::{layer::Context, Layer, prelude::*};
use chrono::Local;
use metrics_exporter_prometheus::PrometheusBuilder;
use tower_http::cors::{Any, CorsLayer};

/// CLI Argument Parsing via Clap
/// This struct defines the "shape" of our terminal commands. 
/// We use the 'derive' feature to automatically convert command-line strings 
/// into typed Rust enums and structs.
#[derive(Parser)]
#[command(name = "conscia")]
#[command(about = "Sovereign Beacon Node for the ExoTalk Mesh", long_about = None)]
struct Args {
    #[command(subcommand)]
    command: Option<Commands>,

    /// Path to configuration file. If omitted, we look in ~/.config/conscia/
    #[arg(short, long, value_name = "FILE")]
    config: Option<PathBuf>,
}

/// Available Subcommands
/// Each variant represents a distinct action the user can take.
#[derive(Subcommand)]
enum Commands {
    /// Start the Conscia beacon daemon (the server mode)
    Daemon,
    /// Show node status and health (is the P2P engine active?)
    Status,
    /// List associated peers (who is currently syncing with us?)
    Peers,
    /// Authorize a peer with specific capabilities (Meadowcap delegation)
    Auth {
        /// Peer Node ID
        id: String,
        /// Role (e.g., Admin, Writer, Reader)
        role: String,
    },
}

/// The Node Configuration Model
/// This is the "brain" of the node's local state. We use Serde to 
/// serialize this to TOML on disk.
#[derive(Serialize, Deserialize, Clone)]
struct Config {
    pub node_name: String,
    pub did: String,
    pub secret: String,
    pub http_port: u16,
    pub federation_active: bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            node_name: "Conscia Beacon".to_string(),
            did: "did:peer:temp".to_string(),
            secret: "CVh7w1QW9GdThiRskD5SYtCyzGLteP4BC6CXR94CFABC".to_string(),
            http_port: 3000,
            federation_active: false,
        }
    }
}

/// GLOBAL ASYNC RUNTIME
/// Rust's 'async' functions don't run themselves; they need an executor.
/// We use a 'Lazy' singleton to ensure that whether we are in daemon mode 
/// or just running a quick 'status' command, we have a consistent, 
/// long-lived Tokio runtime available.
static RUNTIME: Lazy<Runtime> = Lazy::new(|| {
    Runtime::new().expect("Failed to create Tokio runtime")
});

pub fn runtime() -> &'static Runtime {
    &*RUNTIME
}

/// Static Assets
/// We embed the HTML dashboard directly into the binary using 'RustEmbed'.
/// This ensures the CLI is "zero-dependency" and "portable"—no need to 
/// copy folder full of HTML files to the server.
#[derive(RustEmbed)]
#[folder = "../assets/"]
struct Assets;

#[derive(Clone, Serialize, Deserialize, Debug)]
struct LogPayload {
    timestamp: String,
    level: String,
    target: String,
    message: String,
}

/// LOG STREAMING (SSE)
/// We broadcast system logs to the web dashboard in real-time.
/// The LOG_TX channel allows the tracing subscriber to "fire and forget" 
/// logs, which are then picked up by the SSE endpoint.
static LOG_TX: Lazy<tokio::sync::broadcast::Sender<LogPayload>> = Lazy::new(|| {
    let (tx, _) = tokio::sync::broadcast::channel(1000);
    tx
});

// ... [Educational comments continued in the handlers]

struct BroadcastLayer;
impl<S: Subscriber> Layer<S> for BroadcastLayer {
    fn on_event(&self, event: &TracingEvent<'_>, _ctx: Context<'_, S>) {
        let mut visitor = StringVisitor { message: String::new() };
        event.record(&mut visitor);
        let metadata = event.metadata();
        let payload = LogPayload {
            timestamp: Local::now().format("%H:%M:%S").to_string(),
            level: metadata.level().to_string(),
            target: metadata.target().to_string(),
            message: visitor.message,
        };
        let _ = LOG_TX.send(payload);
    }
}

struct StringVisitor { message: String }
impl tracing::field::Visit for StringVisitor {
    fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
        if field.name() == "message" {
            self.message = format!("{:?}", value);
            if self.message.starts_with('"') && self.message.ends_with('"') {
                self.message = self.message[1..self.message.len()-1].to_string();
            }
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // We use Parser::parse() to handle the command-line arguments we defined in Args.
    let args = Args::parse();
    
    // 1. Locate or Initialize Config
    // We favor the standard user configuration directory (e.g., ~/.config/conscia/)
    // to keep the user's home directory clean and organized.
    let config_path = args.config.unwrap_or_else(|| {
        let mut path = dirs::config_dir().unwrap_or_else(|| PathBuf::from("."));
        path.push("conscia");
        std::fs::create_dir_all(&path).ok();
        path.push("config.toml");
        path
    });

    // On first launch (when no config.toml exists), we MUST guide the user.
    // We only trigger onboarding if the user is attempting to start the daemon.
    let config = if !config_path.exists() {
        if args.command.is_some() && !matches!(args.command, Some(Commands::Daemon)) {
            anyhow::bail!("No configuration found. Please run 'conscia' first to initialize your identity.");
        }
        run_onboarding(&config_path)?
    } else {
        let content = std::fs::read_to_string(&config_path)?;
        toml::from_str(&content)?
    };

    // 2. Route Commands
    // The match statement is our "traffic controller" for subcommands.
    match args.command.unwrap_or(Commands::Daemon) {
        Commands::Daemon => start_daemon(config).await?,
        Commands::Status => {
            let stats = network_internal::get_stats().await;
            println!("--- Conscia Node Status ---");
            println!("Version: {}", env!("CARGO_PKG_VERSION"));
            println!("Node ID: {}", stats.get("node_id").unwrap_or(&"Offline".to_string()));
            println!("Config:  {}", config_path.display());
        },
        Commands::Peers => {
            let peers = network_internal::get_peer_list().await;
            println!("--- Associated Peers ({}) ---", peers.len());
            for (id, caps) in peers {
                println!("- {}: {:?}", id, caps);
            }
        },
        Commands::Auth { id, role } => {
            // Mapping String errors to anyhow allows us to bubble up errors 
            // from the network_internal logic while keeping our CLI output clean.
            network_internal::authorize_node(id.clone(), role.clone()).await
                .map_err(|e| anyhow::anyhow!(e))?;
            println!("Successfully granted '{}' role to node {}.", role, id);
        }
    }

    Ok(())
}

/// THE ONBOARDING WIZARD
/// This is the "User Experience" layer for new node operators.
/// We use 'inquire' to provide a high-fidelity terminal UI with 
/// interactive prompts and selection lists.
fn run_onboarding(path: &std::path::Path) -> anyhow::Result<Config> {
    println!("--- 🛰️ Welcome to Conscia ---");
    println!("No configuration detected. Let's initialize your sovereign node.\n");

    let name = InquireText::new("What should we name this node?")
        .with_default("My Lifeline")
        .prompt()?;

    let role = Select::new("Primary Node Role:", vec!["Personal Lifeline", "Community Relay", "High-Availability Mesh"])
        .prompt()?;

    let port = InquireText::new("Web Dashboard Port:")
        .with_default("3000")
        .prompt()?
        .parse::<u16>()
        .unwrap_or(3000);

    println!("\nGenerating sovereign identity...");
    // IDENTITY SYNTHESIS:
    // We generate a real Ed25519 keypair so this node has a mathematically
    // unique did:peer identity from its very first boot.
    let signing_key = ed25519_dalek::SigningKey::generate(&mut rand::rngs::OsRng);
    let secret_b58 = bs58::encode(signing_key.to_bytes()).into_string();
    let public_b58 = bs58::encode(signing_key.verifying_key().to_bytes()).into_string();
    let node_did = format!("did:peer:{}", public_b58);

    let config = Config {
        node_name: name,
        did: node_did,
        secret: secret_b58,
        http_port: port,
        federation_active: role == "High-Availability Mesh",
    };

    // PERSISTENCE: 
    // We save the identity to disk in TOML format. This is the only 
    // persistent state required for the node to resume its mesh role.
    let toml = toml::to_string_pretty(&config)?;
    std::fs::write(path, toml)?;
    println!("Configuration saved to: {}", path.display());
    println!("Identity established successfully.\n");

    Ok(config)
}

/// THE DAEMON LOOP
/// This is the long-lived process that runs the HTTP server and the Iroh node.
async fn start_daemon(config: Config) -> anyhow::Result<()> {
    // We initialize logging here so that daemon-specific logs are captured 
    // and broadcast to the SSE stream.
    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .with(BroadcastLayer)
        .init();
        
    println!("--- 🌎 {} Starting ---", config.node_name);

    let metrics_handle = PrometheusBuilder::new()
        .install_recorder()
        .map_err(|e| anyhow::anyhow!("Failed to install metrics recorder: {}", e))?;

    // 1. START THE ENGINE
    // This is the hand-off to the P2P networking layer.
    network_internal::start_iroh_node(config.did, config.secret).await 
        .map_err(|e| anyhow::anyhow!("Failed to start networking: {}", e))?;
    
    let stats = network_internal::get_stats().await;
    println!("Node initialized: {}", stats.get("node_id").unwrap_or(&"Unknown".to_string()));

    // 2. THE DASHBOARD API
    // We use Axum for a fast, type-safe HTTP interface.
    let app = Router::new()
        .route("/", get(serve_dashboard))
        .route("/api/stats", get(get_live_stats))
        .route("/api/peers", get(get_peer_list))
        .route("/api/peers/dial", post(dial_peer))
        .route("/api/governance/requests", get(get_governance_requests))
        .route("/api/governance/roles", get(get_governance_roles))
        .route("/api/governance/authorize", post(authorize_peer))
        .route("/api/federation/toggle", post(toggle_federation))
        .route("/api/logs/stream", get(stream_logs))
        .route("/api/discovery", get(get_discovery))
        .route("/api/capabilities", get(get_capabilities))
        .route("/api/capabilities/petition", post(submit_petition))
        .route("/api/capabilities/verify", post(verify_capability))
        .route("/api/index/metadata", post(inject_metadata))
        .route("/api/index/search", get(search_metadata))
        .route("/metrics", get(move || async move { metrics_handle.render() }))
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        );

    let addr = SocketAddr::from(([0, 0, 0, 0], config.http_port));
    let listener = tokio::net::TcpListener::bind(addr).await?;
    println!("Web dashboard live at http://localhost:{}", config.http_port);
    
    // START THE WEB SERVER
    axum::serve(listener, app).await?;
    Ok(())
}
// ... [Remaining handlers are self-documenting API endpoints]

async fn dial_peer(Json(payload): Json<serde_json::Value>) -> Result<impl IntoResponse, (StatusCode, String)> {
    let node_id_str = payload["node_id"].as_str().ok_or((StatusCode::BAD_REQUEST, "Missing node_id".to_string()))?;
    network_internal::set_associated_conscia(node_id_str.to_string()).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    Ok(StatusCode::OK)
}

async fn serve_dashboard() -> Html<String> {
    let index = Assets::get("index.html").expect("Failed to load embedded dashboard");
    let template = std::str::from_utf8(index.data.as_ref()).expect("Invalid dashboard template");
    Html(template.to_string())
}

async fn get_live_stats() -> Json<HashMap<String, String>> {
    let mut stats = network_internal::get_stats().await;
    stats.insert("version".to_string(), env!("CARGO_PKG_VERSION").to_string());
    Json(stats)
}

async fn get_peer_list() -> Json<Vec<(String, Vec<String>)>> {
    Json(network_internal::get_peer_list().await)
}

async fn get_governance_requests() -> Json<Vec<String>> {
    Json(network_internal::get_pending_requests().await)
}

async fn get_governance_roles() -> Json<HashMap<String, String>> {
    Json(network_internal::get_all_capabilities().await)
}

#[derive(Deserialize)]
struct AuthPayload {
    id: String,
    role: String,
}

async fn authorize_peer(Json(payload): Json<AuthPayload>) -> Result<impl IntoResponse, (StatusCode, String)> {
    network_internal::authorize_node(payload.id, payload.role).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    Ok(StatusCode::OK)
}

async fn toggle_federation(Json(payload): Json<serde_json::Value>) -> Result<impl IntoResponse, (StatusCode, String)> {
    let active = payload["active"].as_bool().unwrap_or(false);
    if active {
        let namespace = exotalk_core::protocol_internal::derive_namespace("conscia_mesh_governance");
        network_internal::join_conversation_topic(namespace).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e))?;
    }
    Ok(StatusCode::OK)
}

async fn stream_logs(Query(params): Query<LogParams>) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let rx = LOG_TX.subscribe();
    let target_level = params.level.unwrap_or_else(|| "INFO".to_string()).to_uppercase();

    let stream = BroadcastStream::new(rx)
        .filter_map(move |res| {
            if let Ok(payload) = res {
                if payload.level == target_level {
                    if let Ok(json) = serde_json::to_string(&payload) {
                        return Some(Ok(Event::default().data(json)));
                    }
                }
            }
            None
        });

    Sse::new(stream).keep_alive(axum::response::sse::KeepAlive::new())
}

#[derive(Deserialize)]
struct LogParams {
    level: Option<String>,
}

// =============================================================================
// PHASE 4: DISCOVERY, SDUI & BLIND INDEXING ENDPOINTS
// =============================================================================
// 🧠 EDUCATIONAL CONTEXT: The Triad Architecture mandates that host apps 
// (like ThreeSteps or RepubLet) are independent of the network stack. 
// These endpoints allow them to securely "Discover" the Conscia node, query
// its capabilities, and fetch the exact UI components they are allowed to paint.

#[derive(Serialize)]
struct DiscoveryResponse {
    did: String,
    node_id: String,
    version: String,
}

async fn get_discovery() -> Json<DiscoveryResponse> {
    let stats = network_internal::get_stats().await;
    let actual_did = network_internal::get_beacon_did().await.unwrap_or_else(|| "Offline".to_string());
    Json(DiscoveryResponse {
        did: actual_did,
        node_id: stats.get("node_id").cloned().unwrap_or_else(|| "Offline".to_string()),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}

#[derive(Serialize)]
struct CapabilitiesResponse {
    node_role: String,
    performance_target: serde_json::Value,
    sdui_widgets: Vec<String>,
}

/// 💡 MENTOR TIP: Server-Driven UI (SDUI)
/// Instead of hardcoding widgets in the client app, we tell the client exactly
/// what to render based on the node's performance profile and federation status.
/// This prevents a mobile app from crashing a lightweight node with heavy queries!
async fn get_capabilities() -> Json<CapabilitiesResponse> {
    Json(CapabilitiesResponse {
        node_role: "High-Availability Mesh".to_string(), // Contextually derived in production
        performance_target: serde_json::json!({
            "cpu_idle_target": 1.3,
            "render_mode": "moses_pulse"
        }),
        sdui_widgets: vec![
            "FederationToggle".to_string(),
            "RoleDropdown".to_string(),
            "MetadataSearch".to_string(),
        ],
    })
}

#[derive(Deserialize)]
struct PetitionPayload {
    did: String,
    role_requested: String,
}

async fn submit_petition(Json(payload): Json<PetitionPayload>) -> Result<impl IntoResponse, (StatusCode, String)> {
    let mut pending = network_internal::PENDING_REQUESTS.write().await;
    if !pending.contains(&payload.did) {
        pending.push(payload.did.clone());
        tracing::info!("External petition queued for DID: {} (Requested: {})", payload.did, payload.role_requested);
    }
    Ok(StatusCode::OK)
}

#[derive(Deserialize)]
struct VerifyPayload {
    did: String,
}

#[derive(Serialize)]
struct VerifyResponse {
    permission_level: String,
}

async fn verify_capability(Json(payload): Json<VerifyPayload>) -> Json<VerifyResponse> {
    let store = network_internal::CAPABILITY_STORE.read().await;
    // We use the mesh governance namespace for base access level checks
    let namespace = exotalk_core::protocol_internal::derive_namespace("conscia_mesh_governance");
    
    let permission_level = if let Some(ns_map) = store.get(&namespace) {
        if let Some(level) = ns_map.get(&payload.did) {
            format!("{:?}", level)
        } else {
            "None".to_string()
        }
    } else {
        "None".to_string()
    };
    
    Json(VerifyResponse { permission_level })
}

#[derive(Deserialize, Serialize, Clone)]
struct MetadataPayload {
    author_did: String,
    content_hash: String,
    metadata_tags: Vec<String>,
    signature: String,
}

// 🧠 EDUCATIONAL CONTEXT: Blind Indexing
// As a "Sovereign Beacon", this node indexes metadata tags for global search 
// (like RepubLet articles) without ever needing the keys to decrypt the 
// underlying content payloads.
// In-memory store for blind indexing (ephemeral for this version)
static METADATA_INDEX: Lazy<tokio::sync::RwLock<Vec<MetadataPayload>>> = Lazy::new(|| tokio::sync::RwLock::new(Vec::new()));

async fn inject_metadata(Json(payload): Json<MetadataPayload>) -> Result<impl IntoResponse, (StatusCode, String)> {
    let mut index = METADATA_INDEX.write().await;
    index.push(payload.clone());
    tracing::info!("Indexed new public metadata for encrypted content hash: {}", payload.content_hash);
    Ok(StatusCode::OK)
}

#[derive(Deserialize)]
struct SearchQuery {
    query: String,
}

async fn search_metadata(Query(params): Query<SearchQuery>) -> Json<Vec<MetadataPayload>> {
    let index = METADATA_INDEX.read().await;
    let query_lower = params.query.to_lowercase();
    let results: Vec<MetadataPayload> = index.iter()
        .filter(|m| m.metadata_tags.iter().any(|t| t.to_lowercase().contains(&query_lower)))
        .cloned()
        .collect();
    Json(results)
}

