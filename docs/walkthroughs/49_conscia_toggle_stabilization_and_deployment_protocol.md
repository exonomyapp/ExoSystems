# Walkthrough 49: Instrumented Service Lifecycle Control & Performance Audit

This walkthrough documents the stabilization of the Bridge Monitor's interactive controls, the formalization of the "Service Toggle" architecture, and the discovery of a significant CPU usage regression.

## 🔍 Root Cause Analysis (Conscia Toggle)

### The Problem
When clicking the Conscia Tristate Toggle from the desktop icon on Exonomy, the toggle would briefly flash green (ON), then immediately revert to red (OFF) and become permanently unresponsive.

### The Fix
1. **Absolute Binary Path**: Replaced `cargo run` with the absolute path to the pre-compiled binary (`/home/exocrat/.../target/release/conscia daemon`), eliminating PATH dependency issues in the desktop context.
2. **Defensive try/finally**: Wrapped the state transition in a `try/finally` block to guarantee that the `_isProcessing` guard is always reset, even on subprocess failure.
3. **Unified Code Paths**: Synchronized the keyboard shortcut handler (`_cycleConscia`) and the mouse click handler to use the same logic and binary path.

## 🏷️ Naming & Instrumentation Overhaul

We transitioned the technology from "Kill Switches" to **Instrumented Service Lifecycle Control**:

- **NodeKillSwitch** → **NodeServiceToggle**: Reflects standard bilateral service control (Signaling/Proxy) via `systemctl`.
- **Instrumentation**: Added universal click logging to `~/bridge_monitor_clicks.log`. Every toggle action (On/Off/Sleep) across all three nodes is now timestamped and ID-aware for remote verification.
- **Node IDs**: Renamed `beacon-1` to `conscia-1` for architectural clarity.

## ⚡ Performance Audit: 1s Refresh & CPU Load

### Polling Frequency
The telemetry polling interval was reduced from **5 seconds** to **1 second** to provide near-instant feedback for external service changes.

### CPU Usage Regression
During testing, we observed that the Bridge Monitor consumes **30-40% CPU** when idle.
- **Visual Evidence**: [Exonomy Resource Monitor (htop)](file:///home/exocrat/code/exotalk/exonomy_htop.png) shows a dramatic drop to ~5% CPU immediately after the Bridge app is closed.
- **Analysis**: The overhead is likely caused by the high-frequency subprocess spawning (`systemctl`, `pgrep`, `tail`) required for telemetry, combined with Flutter's animation loop. This is flagged for a dedicated optimization campaign in the next session.

## 📋 Agent Protocol Improvements (agent.md)

- **Section 6.1.2 (Deployment Pathway)**: Added explicit instructions to compile locally on Exocracy and deploy only the release bundle via `scp`.
- **Section 2 (Session Continuity)**: Mandated checking the `overview.txt` log of the prior session to ensure continuity of architectural decisions.

## 📝 Document Checklist

| File | Status |
|---|---|
| `infra/bridge_monitor/lib/main.dart` | Renamed components, 1s refresh, try/finally guards, unified logging. |
| `infra/bridge_monitor/README.md` | Updated features, deployment pathway, and walkthrough links. |
| `docs/spec/telemetry_verification.md` | Updated to reflect 1s polling and absolute binary paths. |
| `agent.md` | Updated with deployment and continuity protocols. |
| `improvement_notes.md` | **[NEW]** Captures CPU profiling goals for the next session. |

## 🚀 Deployment Status

- **Build**: `flutter build linux --release` ✅
- **Transfer**: Release bundle deployed to Exonomy via `scp` ✅
- **KDVV**: Click logging verified for all three nodes ✅

## ⏭️ What's Next

1. **CPU Optimization Campaign**: Research native FFI or socket-based process monitoring to replace subprocess spawning.
2. **Tutorial Recording**: Commencing the "Sovereign Handshake" screenplay using the stabilized monitor.
3. **Desktop Cleanup**: Remove redundant `.desktop` files (Exonomy has 3 identical launchers).
