// =============================================================================
// INSTALLATION EXECUTOR
// =============================================================================
// 🧠 EDUCATIONAL CONTEXT: The Executor — Idempotent FHS Provisioning
// This module consumes a finalized InstallerConfig and executes the 10-step
// action sequence defined in §6.3 of the FHS Installer Specification.
//
// Every step is designed to be IDEMPOTENT — running the installer twice on
// the same machine produces the exact same result. This is critical for:
//   - Upgrades: replace binaries without losing identity keys
//   - Recovery: re-run after a partial failure
//   - Fleet management: scripted re-provisioning across many nodes

use std::fs;
use std::os::unix::fs::{chown, PermissionsExt};
use std::process::Command;

use console::style;
use indicatif::{ProgressBar, ProgressStyle};

use crate::config::*;

/// Execute the full FHS installation sequence.
pub fn execute(config: &InstallerConfig) -> anyhow::Result<()> {
    let steps = calculate_step_count(config);
    let pb = ProgressBar::new(steps as u64);
    pb.set_style(
        ProgressStyle::with_template(
            "{spinner:.green} [{bar:40.cyan/blue}] {pos}/{len} {msg}"
        )?
        .progress_chars("█▓░"),
    );

    // ── Step 1: Create exo-sys user ──────────────────────────────────────
    pb.set_message("Creating service user...");
    create_service_user()?;
    pb.inc(1);

    // ── Step 2: Create FHS directories ───────────────────────────────────
    pb.set_message("Creating FHS directories...");
    create_fhs_directories(config)?;
    pb.inc(1);

    // ── Step 3: Copy binaries ────────────────────────────────────────────
    pb.set_message("Installing binaries...");
    // 🧠 PLACEHOLDER: In production, this copies from a staged `dist/` directory
    // created by the Makefile's `package` target. For now, we create the
    // directory structure so systemd units have valid paths.
    ensure_dir(&format!("{}/conscia", FHS_OPT))?;
    if config.components.consoul {
        ensure_dir(&format!("{}/ui", FHS_OPT))?;
    }
    if config.components.zrok {
        ensure_dir(&format!("{}/zrok", FHS_OPT))?;
    }
    pb.inc(1);

    // ── Step 4: Write .env configuration files ───────────────────────────
    pb.set_message("Writing configuration...");
    write_env_files(config)?;
    pb.inc(1);

    // ── Step 5: Install systemd unit files ───────────────────────────────
    pb.set_message("Installing systemd units...");
    install_systemd_units(config)?;
    pb.inc(1);

    // ── Step 6: Install logrotate configuration ──────────────────────────
    pb.set_message("Configuring log rotation...");
    install_logrotate()?;
    pb.inc(1);

    // ── Step 7: Install ConSoul .desktop launcher ────────────────────────
    if config.components.consoul {
        pb.set_message("Installing ConSoul launcher...");
        install_desktop_launcher()?;
        pb.inc(1);
    }

    // ── Step 8: Reload systemd ───────────────────────────────────────────
    pb.set_message("Reloading systemd...");
    run_cmd("systemctl", &["daemon-reload"])?;
    pb.inc(1);

    // ── Step 9: Enable and start services ────────────────────────────────
    pb.set_message("Starting services...");
    enable_services(config)?;
    pb.inc(1);

    pb.finish_with_message("Installation complete!");
    println!();

    Ok(())
}

fn calculate_step_count(config: &InstallerConfig) -> usize {
    let mut steps = 8; // Base steps (user, dirs, binaries, env, systemd, logrotate, reload, start)
    if config.components.consoul {
        steps += 1; // Desktop launcher
    }
    steps
}

/// Create the exo-sys service user if it doesn't exist.
fn create_service_user() -> anyhow::Result<()> {
    // 🧠 EDUCATIONAL CONTEXT: Idempotent User Creation
    // We check if the user exists before creating. The `id` command returns
    // exit code 0 if the user exists, non-zero otherwise.
    let exists = Command::new("id")
        .arg("-u")
        .arg(SERVICE_USER)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if !exists {
        run_cmd("useradd", &[
            "-r",                    // System account
            "-s", "/usr/sbin/nologin", // No interactive login
            "-d", FHS_VAR_LIB,       // Home directory
            "-m",                    // Create home dir
            SERVICE_USER,
        ])?;
        println!("  {} Created service user: {}", style("✓").green(), SERVICE_USER);
    } else {
        println!("  {} Service user already exists: {}", style("·").dim(), SERVICE_USER);
    }
    Ok(())
}

/// Create all FHS directories with correct ownership and permissions.
fn create_fhs_directories(config: &InstallerConfig) -> anyhow::Result<()> {
    // /opt/exo/ — root:root 0755
    ensure_dir(FHS_OPT)?;
    set_ownership(FHS_OPT, 0, 0)?;  // root:root
    set_permissions(FHS_OPT, 0o755)?;

    // /etc/exo/ — root:exo-sys 0750
    ensure_dir(FHS_ETC)?;
    let gid = get_group_id(SERVICE_USER)?;
    set_ownership(FHS_ETC, 0, gid)?;
    set_permissions(FHS_ETC, 0o750)?;

    // /var/lib/exo/ — exo-sys:exo-sys 0700
    ensure_dir(FHS_VAR_LIB)?;
    let uid = get_user_id(SERVICE_USER)?;
    set_ownership(FHS_VAR_LIB, uid, gid)?;
    set_permissions(FHS_VAR_LIB, 0o700)?;

    // Create subdirectories for persistent state
    for subdir in &["identity", "willow", "capabilities"] {
        let path = format!("{}/{}", FHS_VAR_LIB, subdir);
        ensure_dir(&path)?;
        set_ownership(&path, uid, gid)?;
        set_permissions(&path, 0o700)?;
    }
    if config.components.zrok {
        let zrok_state = format!("{}/zrok", FHS_VAR_LIB);
        ensure_dir(&zrok_state)?;
        set_ownership(&zrok_state, uid, gid)?;
        set_permissions(&zrok_state, 0o700)?;
    }

    // /var/log/exo/ — exo-sys:exo-sys 0755
    ensure_dir(FHS_VAR_LOG)?;
    set_ownership(FHS_VAR_LOG, uid, gid)?;
    set_permissions(FHS_VAR_LOG, 0o755)?;

    println!("  {} FHS directories created", style("✓").green());
    Ok(())
}

/// Write .env configuration files for each component.
fn write_env_files(config: &InstallerConfig) -> anyhow::Result<()> {
    // conscia.env
    let conscia_env = format!(
        "# Conscia Daemon Configuration\n\
         # Generated by exo-installer v{}\n\
         CONSCIA_MESH_NAMESPACE={}\n\
         CONSCIA_API_PORT={}\n\
         CONSCIA_LOG_LEVEL=info\n",
        env!("CARGO_PKG_VERSION"),
        config.conscia.mesh_namespace,
        config.conscia.api_port,
    );
    fs::write(format!("{}/conscia.env", FHS_ETC), &conscia_env)?;

    // zrok.env (if selected)
    if let Some(ref zrok) = config.zrok {
        let zrok_env = format!(
            "# Zrok Tunnel Configuration\n\
             # Generated by exo-installer v{}\n\
             ZROK_SHARE_TOKEN={}\n\
             ZROK_BACKEND_URL={}\n",
            env!("CARGO_PKG_VERSION"),
            zrok.share_token,
            zrok.backend_url,
        );
        fs::write(format!("{}/zrok.env", FHS_ETC), &zrok_env)?;
    }

    // Set permissions on .env files: root:exo-sys 0640
    let gid = get_group_id(SERVICE_USER)?;
    for entry in fs::read_dir(FHS_ETC)? {
        let entry = entry?;
        if entry.path().extension().map_or(false, |e| e == "env") {
            set_ownership(entry.path().to_str().unwrap(), 0, gid)?;
            set_permissions(entry.path().to_str().unwrap(), 0o640)?;
        }
    }

    println!("  {} Configuration files written to {}", style("✓").green(), FHS_ETC);
    Ok(())
}

/// Install systemd unit files from embedded templates.
fn install_systemd_units(config: &InstallerConfig) -> anyhow::Result<()> {
    let conscia_unit = include_str!("../templates/exo-conscia.service");
    fs::write("/etc/systemd/system/exo-conscia.service", conscia_unit)?;

    if config.components.zrok {
        let zrok_unit = include_str!("../templates/exo-zrok.service");
        fs::write("/etc/systemd/system/exo-zrok.service", zrok_unit)?;
    }

    println!("  {} Systemd units installed", style("✓").green());
    Ok(())
}

/// Install logrotate configuration.
fn install_logrotate() -> anyhow::Result<()> {
    let logrotate = include_str!("../templates/exo-logrotate.conf");
    fs::write("/etc/logrotate.d/exo", logrotate)?;
    println!("  {} Logrotate configured", style("✓").green());
    Ok(())
}

/// Install the ConSoul .desktop launcher.
fn install_desktop_launcher() -> anyhow::Result<()> {
    let desktop = include_str!("../templates/consoul.desktop");
    ensure_dir("/usr/share/applications")?;
    fs::write("/usr/share/applications/consoul.desktop", desktop)?;
    println!("  {} ConSoul desktop launcher installed", style("✓").green());
    Ok(())
}

/// Enable and start systemd services.
fn enable_services(config: &InstallerConfig) -> anyhow::Result<()> {
    run_cmd("systemctl", &["enable", "--now", "exo-conscia.service"])?;
    if config.components.zrok {
        run_cmd("systemctl", &["enable", "--now", "exo-zrok.service"])?;
    }
    println!("  {} Services enabled and started", style("✓").green());
    Ok(())
}

// ─── Utility Functions ───────────────────────────────────────────────────────

fn ensure_dir(path: &str) -> anyhow::Result<()> {
    fs::create_dir_all(path)?;
    Ok(())
}

fn set_ownership(path: &str, uid: u32, gid: u32) -> anyhow::Result<()> {
    chown(path, Some(uid), Some(gid))?;
    Ok(())
}

fn set_permissions(path: &str, mode: u32) -> anyhow::Result<()> {
    let perms = fs::Permissions::from_mode(mode);
    fs::set_permissions(path, perms)?;
    Ok(())
}

fn get_user_id(username: &str) -> anyhow::Result<u32> {
    let output = Command::new("id").arg("-u").arg(username).output()?;
    let uid_str = String::from_utf8(output.stdout)?.trim().to_string();
    Ok(uid_str.parse()?)
}

fn get_group_id(username: &str) -> anyhow::Result<u32> {
    let output = Command::new("id").arg("-g").arg(username).output()?;
    let gid_str = String::from_utf8(output.stdout)?.trim().to_string();
    Ok(gid_str.parse()?)
}

fn run_cmd(cmd: &str, args: &[&str]) -> anyhow::Result<()> {
    let status = Command::new(cmd).args(args).status()?;
    if !status.success() {
        anyhow::bail!("Command failed: {} {:?}", cmd, args);
    }
    Ok(())
}
