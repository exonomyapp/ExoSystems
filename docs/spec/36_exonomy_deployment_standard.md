# Spec 36: Exonomy Deployment Standard

## 1. Objective
To establish a deterministic, immutable deployment structure for all ExoTech infrastructure on the Exonomy node, preventing configuration drift and "agent-invented" naming conventions.

## 2. Directory Hierarchy
The Exonomy node (`exocrat@exonomy.local`) follows a strict **`~/deployments/`** baseline.

### 2.1 Bridge Monitor (Dashboard)
- **Path**: `~/deployments/bridge_monitor/`
- **Bundle**: `~/deployments/bridge_monitor/bundle/exotech_bridge`
- **Logs**: `~/bridge_monitor.log`
- **Config**: `~/.exotech_bridge_config.json`

> [!CAUTION]
> The directory `~/ExoTech/Bridge/` is a **decommissioned, obsolete** path from before Spec 36 was established. Any agent that finds it must treat it as legacy debris and **not** deploy to it. The ONLY valid deployment target is `~/deployments/bridge_monitor/bundle/`.

### 2.2 Infrastructure Binaries (Infra)
- **Path**: `~/deployments/infra/`
- **Signaling**: `~/deployments/infra/signaling_server.py`
- **zrok**: `~/deployments/infra/zrok` (Target Version: `v1.1.11 Stable`)
- **Conscia**: `~/deployments/conscia/daemon/conscia` (Target Version: `v0.7.7`)

## 3. Service Orchestration
- All Python and external binary proxies (Signaling, zrok) MUST be orchestrated via **Systemd User Units**.
- **Unit Path**: `/etc/systemd/system/` (Root-level for boot persistence)
- **Naming Convention**: `exotalk-<service>.service`
- **Stable URL Standard**: `<service><nodename>.share.zrok.io` (e.g., `exotalkberlin`, `conscianikolasee`)

## 4. Desktop Launcher (Exonomy)

There are **two** desktop files that MUST be kept in sync on every deployment. Both must point to the formal bundle path. A source-of-truth `.desktop` file is versioned at `infra/bridge_monitor/exotech_bridge.desktop`.

| Location | Purpose |
|---|---|
| `~/Desktop/exotech_bridge.desktop` | Clickable desktop icon |
| `~/.local/share/applications/exotech_bridge.desktop` | App menu / dock launcher |

**Correct file content:**
```ini
[Desktop Entry]
Name=ExoTech Bridge
Comment=Deterministic Mesh Monitoring
Exec=/home/exocrat/deployments/bridge_monitor/bundle/exotech_bridge
Icon=/home/exocrat/deployments/bridge_monitor/bundle/data/flutter_assets/assets/exotalk_pappus_color.png
Terminal=false
Type=Application
Categories=Development;
```

## 5. Deployment Command (Exocracy → Exonomy)

This is the **canonical, exact command** to be run from the Exocracy workstation after every `flutter build linux --release`. Do not invent variations.

```bash
# 1. Transfer the bundle (SCP the entire bundle directory as a unit)
sshpass -p "." scp -r -o StrictHostKeyChecking=no \
  infra/bridge_monitor/build/linux/x64/release/bundle \
  exocrat@exonomy.local:~/deployments/bridge_monitor/

# 2. Sync both desktop launchers from the versioned source
sshpass -p "." scp -o StrictHostKeyChecking=no \
  infra/bridge_monitor/exotech_bridge.desktop \
  exocrat@exonomy.local:~/Desktop/exotech_bridge.desktop
sshpass -p "." ssh -o StrictHostKeyChecking=no exocrat@exonomy.local \
  "chmod +x ~/Desktop/exotech_bridge.desktop && \
   cp ~/Desktop/exotech_bridge.desktop ~/.local/share/applications/exotech_bridge.desktop"
```

> [!IMPORTANT]
> Before running the SCP command, you MUST wipe the remote bundle directory first to prevent stale files from accumulating:
> `sshpass -p "." ssh -o StrictHostKeyChecking=no exocrat@exonomy.local "rm -rf ~/deployments/bridge_monitor/bundle"`

## 6. Verification Protocol (KDVV)
- All deployment updates MUST be verified using the **Bridge Monitor** UI.
- Programmatic verification via `pgrep` or `systemctl status` must accompany all UI-based "amen" confirmations.
- CPU overhead for the diagnostic layer MUST NOT exceed **10%** of total system resources.

