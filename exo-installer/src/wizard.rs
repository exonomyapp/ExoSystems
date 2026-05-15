// =============================================================================
// INTERACTIVE WIZARD (Tier 2: inquire)
// =============================================================================
// EDUCATIONAL CONTEXT: Per Spec 07 §7.7, the installer uses `inquire`
// (Tier 2: Interactive) for guided configuration. This is NOT a persistent
// dashboard — it's a one-shot wizard that builds an InstallerConfig and
// then hands off to the executor.
//
// The wizard flow maps 1:1 to §6.2 of the FHS Installer Specification:
//   1. Component Selection → MultiSelect
//   2. Conscia Config → Text prompts
//   3. Zrok Config (conditional) → Password + Text
//   4. Topology Preview → Formatted console output
//   5. Confirmation → Confirm prompt

use console::style;
use inquire::{Confirm, MultiSelect, Password, Text};

use crate::config::*;

/// Run the interactive wizard flow and return a finalized InstallerConfig.
pub fn run_wizard() -> anyhow::Result<InstallerConfig> {
    println!();
    println!("{}", style("═══════════════════════════════════════════════════").cyan());
    println!("{}", style("   Conscia node — FHS Installer").cyan().bold());
    println!("{}", style("═══════════════════════════════════════════════════").cyan());
    println!();

    // ── Step 1: Component Selection ──────────────────────────────────────
    // Conscia is always installed. ConSoul and Zrok
    // are optional — ConSoul is the desktop admin UI, and Zrok provides
    // public HTTPS URLs which are NOT required for the P2P mesh to function.
    let options = vec!["ConSoul (Desktop Admin Console)", "Zrok (Public HTTPS Tunnel)"];
    let defaults = vec![0]; // ConSoul selected by default

    let selected = MultiSelect::new(
        "Select optional components (Conscia daemon is always installed):",
        options,
    )
    .with_default(&defaults)
    .prompt()?;

    let components = ComponentSelection {
        conscia: true, // Always on
        consoul: selected.contains(&"ConSoul (Desktop Admin Console)"),
        zrok: selected.contains(&"Zrok (Public HTTPS Tunnel)"),
    };

    // ── Step 2: Conscia Configuration ────────────────────────────────────
    println!();
    println!("{}", style("── Conscia Daemon Configuration ──").yellow().bold());

    let mesh_namespace = Text::new("Mesh namespace:")
        .with_default("exo_mesh")
        .with_help_message("A human-readable identifier for your mesh network")
        .prompt()?;

    let api_port: u16 = Text::new("API port:")
        .with_default("3000")
        .with_help_message("HTTP/WebSocket port for the Conscia API (includes signaling)")
        .prompt()?
        .parse()
        .unwrap_or(3000);

    let generate_new = Confirm::new("Generate a new cryptographic identity (Ed25519 keypair)?")
        .with_default(true)
        .with_help_message("Select 'No' to import an existing DID seed")
        .prompt()?;

    let conscia_config = ConsciaConfig {
        mesh_namespace,
        api_port,
        generate_new_identity: generate_new,
    };

    // ── Step 3: Zrok Configuration (conditional) ─────────────────────────
    let zrok_config = if components.zrok {
        println!();
        println!("{}", style("── Zrok Tunnel Configuration ──").yellow().bold());
        println!("{}", style("  Zrok is optional — the P2P mesh works without it.").dim());
        println!("{}", style("  It provides public HTTPS URLs for remote browser access.").dim());

        let token = Password::new("Zrok reserved share token:")
            .with_help_message("The token from 'zrok reserve public' (e.g., 'exotalkberlin')")
            .prompt()?;

        let backend = Text::new("Backend URL to proxy:")
            .with_default(&format!("http://localhost:{}", conscia_config.api_port))
            .prompt()?;

        Some(ZrokConfig {
            share_token: token,
            backend_url: backend,
        })
    } else {
        None
    };

    let config = InstallerConfig {
        components,
        conscia: conscia_config,
        zrok: zrok_config,
    };

    // ── Step 4: Topology Preview ─────────────────────────────────────────
    print_topology_preview(&config);

    // ── Step 5: Confirmation ─────────────────────────────────────────────
    println!();
    let confirmed = Confirm::new("Proceed with installation?")
        .with_default(false)
        .with_help_message("No files will be written until you confirm")
        .prompt()?;

    if !confirmed {
        println!("{}", style("Installation cancelled.").red());
        std::process::exit(0);
    }

    Ok(config)
}

/// Display a formatted summary of what the installer will do.
fn print_topology_preview(config: &InstallerConfig) {
    println!();
    println!("{}", style("═══════════════════════════════════════════════════").green());
    println!("{}", style("   Installation Preview").green().bold());
    println!("{}", style("═══════════════════════════════════════════════════").green());
    println!();

    // Components
    println!("{}", style("Components:").bold());
    println!("  Conscia daemon ({}:{})", config.conscia.mesh_namespace, config.conscia.api_port);
    if config.components.consoul {
        println!("  ConSoul desktop admin console");
    }
    if config.components.zrok {
        if let Some(ref zrok) = config.zrok {
            println!("  Zrok tunnel → {}", zrok.backend_url);
        }
    }

    // FHS Directory Layout
    println!();
    println!("{}", style("FHS Directory Layout:").bold());
    println!("  {} → Conscia binary", style(format!("{}/conscia/", FHS_OPT)).cyan());
    if config.components.consoul {
        println!("  {} → ConSoul Flutter bundle", style(format!("{}/ui/", FHS_OPT)).cyan());
    }
    println!("  {} → .env config files", style(FHS_ETC).cyan());
    println!("  {} → Identity keys, Willow state", style(FHS_VAR_LIB).cyan());
    println!("  {} → Logrotated diagnostics", style(FHS_VAR_LOG).cyan());

    // Systemd Units
    println!();
    println!("{}", style("Systemd Units:").bold());
    println!("  • exo-conscia.service (User={})", SERVICE_USER);
    if config.components.zrok {
        println!("  • exo-zrok.service (User={})", SERVICE_USER);
    }

    // Security
    println!();
    println!("{}", style("Security:").bold());
    println!("  • Service user: {} (non-login, headless)", style(SERVICE_USER).yellow());
    println!("  • {}/: owned by root:root (0755)", FHS_OPT);
    println!("  • {}/: owned by root:{} (0750)", FHS_ETC, SERVICE_USER);
    println!("  • {}/: owned by {}:{} (0700)", FHS_VAR_LIB, SERVICE_USER, SERVICE_USER);
}
