// =============================================================================
// INSTALLER CONFIGURATION MODEL
// =============================================================================
// 🧠 EDUCATIONAL CONTEXT: The InstallerConfig Struct
// This is the central data store that accumulates user selections across all
// wizard steps. It is serializable to TOML so that an operator can:
//   1. Run the wizard once interactively to generate a config file.
//   2. Re-run the installer headlessly with `--config saved.toml` for
//      reproducible deployments across multiple nodes.
//
// The config is a "state builder" — it captures intent without executing
// any filesystem changes. Execution only happens when the operator confirms.

use serde::{Deserialize, Serialize};

/// Which components the operator selected for installation.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ComponentSelection {
    /// Conscia daemon — always required (the sovereign lifeline)
    pub conscia: bool,
    /// ConSoul desktop admin console
    pub consoul: bool,
    /// Zrok overlay tunnel — optional convenience for public HTTPS URLs
    pub zrok: bool,
}

impl Default for ComponentSelection {
    fn default() -> Self {
        Self {
            conscia: true,  // Always on — the core lifeline
            consoul: true,
            zrok: false,    // Optional — not required for P2P mesh
        }
    }
}

/// Configuration for the Conscia daemon.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ConsciaConfig {
    /// Human-readable mesh namespace identifier
    pub mesh_namespace: String,
    /// API bind port for the HTTP/WebSocket interface
    pub api_port: u16,
    /// Whether to generate a fresh DID keypair or import an existing one
    pub generate_new_identity: bool,
}

impl Default for ConsciaConfig {
    fn default() -> Self {
        Self {
            mesh_namespace: "sovereign_mesh".to_string(),
            api_port: 3000,
            generate_new_identity: true,
        }
    }
}

/// Configuration for the Zrok tunnel (only if selected).
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct ZrokConfig {
    /// The reserved share token (e.g., "exotalkberlin")
    pub share_token: String,
    /// Backend URL to proxy (e.g., "http://localhost:3000")
    pub backend_url: String,
}

/// The complete installer configuration — accumulated across wizard steps.
#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct InstallerConfig {
    pub components: ComponentSelection,
    pub conscia: ConsciaConfig,
    pub zrok: Option<ZrokConfig>,
}

impl Default for InstallerConfig {
    fn default() -> Self {
        Self {
            components: ComponentSelection::default(),
            conscia: ConsciaConfig::default(),
            zrok: None,
        }
    }
}

// 🧠 EDUCATIONAL CONTEXT: FHS Path Constants
// These are the enterprise-standard directories defined in the
// FHS Installer Specification (docs/releases/fhs_installer_specification.md).
// They are NOT configurable — the entire point of FHS compliance is
// deterministic, predictable paths across all deployment targets.

/// Immutable application binaries
pub const FHS_OPT: &str = "/opt/exo";
/// Configuration files (systemd .env, node.conf)
pub const FHS_ETC: &str = "/etc/exo";
/// Persistent state (identity keys, Willow data, capabilities)
pub const FHS_VAR_LIB: &str = "/var/lib/exo";
/// Centralized logs (logrotated)
pub const FHS_VAR_LOG: &str = "/var/log/exo";
/// The headless service user
pub const SERVICE_USER: &str = "exo-sys";
