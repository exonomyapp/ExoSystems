// =============================================================================
// EXO-INSTALLER: Conscia node — FHS Installer
// =============================================================================
// EDUCATIONAL CONTEXT: The "Process IS The Product" Mandate
// The SOFTWARE ITSELF is the installer. This binary automates every step of
// the FHS deployment: user creation, directory provisioning,
// binary placement, systemd registration, and health verification.
//
// This is a Tier 2 Interactive tool (per Spec 07 §7.7) using `inquire`
// for guided configuration wizards. The Tier 3 TUI (`ratatui`) is reserved
// for the Conscia monitoring dashboard — a separate project.
//
// Usage:
//   sudo exo-installer              # Interactive wizard
//   sudo exo-installer --config f   # Headless re-install from saved config

mod config;
mod executor;
mod health;
mod wizard;

use clap::Parser;
use console::style;
use std::path::PathBuf;

/// Conscia node — FHS-Compliant Installer
#[derive(Parser)]
#[command(name = "exo-installer")]
#[command(about = "Interactive FHS-compliant installer for the Conscia node")]
#[command(version)]
struct Args {
    /// Path to a saved TOML configuration file for headless re-installation.
    /// Generate one by running the wizard and saving the output.
    #[arg(short, long, value_name = "FILE")]
    config: Option<PathBuf>,

    /// Save the wizard configuration to a file without installing.
    /// Useful for generating reproducible configs for fleet deployments.
    #[arg(long, value_name = "FILE")]
    save_config: Option<PathBuf>,
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    // ── Root Privilege Check ─────────────────────────────────────────────
    // EDUCATIONAL CONTEXT: The installer writes to /opt, /etc, /var,
    // creates system users, and manages systemd units. All of these require
    // root privileges. We check early and exit rather than
    // halting during execution.
    if !nix::unistd::getuid().is_root() {
        eprintln!("{}", style("Error: This installer must be run as root (sudo).").red().bold());
        eprintln!("{}", style("  Usage: sudo exo-installer").dim());
        std::process::exit(1);
    }

    // ── Configuration Acquisition ────────────────────────────────────────
    let installer_config = if let Some(config_path) = args.config {
        // Headless mode: load from saved TOML
        println!("{}", style("Loading configuration from file...").dim());
        let content = std::fs::read_to_string(&config_path)?;
        toml::from_str(&content)?
    } else {
        // Interactive mode: run the wizard
        wizard::run_wizard()?
    };

    // ── Save Config (if requested) ───────────────────────────────────────
    if let Some(save_path) = args.save_config {
        let toml_str = toml::to_string_pretty(&installer_config)?;
        std::fs::write(&save_path, &toml_str)?;
        println!("{} Configuration saved to: {}", style("✓").green(), save_path.display());
        return Ok(());
    }

    // ── Execute Installation ─────────────────────────────────────────────
    executor::execute(&installer_config)?;

    // ── Health Check ─────────────────────────────────────────────────────
    health::run_health_check(&installer_config);

    println!("{}", style("Conscia node — Installation Complete!").green().bold());
    println!();

    Ok(())
}
