// =============================================================================
// POST-INSTALL HEALTH CHECK
// =============================================================================
// 🧠 EDUCATIONAL CONTEXT: Trust But Verify
// After the executor finishes, we don't just assume everything worked.
// We query systemd for the actual state of each installed service.
// This is step 10 of the FHS Installer Specification §6.3.

use std::process::Command;
use console::style;

use crate::config::InstallerConfig;

/// Run post-install health checks for all installed services.
pub fn run_health_check(config: &InstallerConfig) {
    println!();
    println!("{}", style("═══════════════════════════════════════════════════").green());
    println!("{}", style("   🏥 Post-Install Health Check").green().bold());
    println!("{}", style("═══════════════════════════════════════════════════").green());
    println!();

    check_service("exo-conscia.service");

    if config.components.zrok {
        check_service("exo-zrok.service");
    }

    println!();
}

/// Check if a systemd service is active.
fn check_service(name: &str) {
    let output = Command::new("systemctl")
        .arg("is-active")
        .arg(name)
        .output();

    match output {
        Ok(o) => {
            let status = String::from_utf8_lossy(&o.stdout).trim().to_string();
            if status == "active" {
                println!("  {} {} → {}", style("✅").green(), name, style("active (running)").green());
            } else {
                println!("  {} {} → {}", style("❌").red(), name, style(&status).red());
            }
        }
        Err(e) => {
            println!("  {} {} → {}", style("❌").red(), name, style(format!("check failed: {}", e)).red());
        }
    }
}
