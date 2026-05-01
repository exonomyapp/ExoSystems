# Walkthrough: Real-Time Telemetry & Global UI Scaling

I have successfully transitioned the Conscia dashboard from a static binary status to a multi-stage network health diagnostic system and implemented global accessibility scaling for the ExoTalk Flutter application.

## 1. Multi-Stage Network Health Telemetry

The Conscia dashboard now monitors the **"5 Stages of Connectivity Success"** in real-time, allowing operators to diagnose exactly where a P2P failure is occurring.

### Backend Diagnostic Engine
- Refactored `exotalk_core/src/network_internal.rs` to extract deep telemetry from the `iroh::Endpoint`.
- Implemented a custom `tracing_subscriber::Layer` to intercept all engine logs and broadcast them via JSON.
- Added a new Axum SSE endpoint at `/api/logs/stream` for real-time log delivery.

### Dashboard UI Overhaul
- **Health Tracker:** A 5-stage horizontal visualizer tracking Engine Initialization, Local UDP Binding, Relay/Internet Reachability, Peer Mesh Count, and Gossip Subscriptions.
- **Log Stream Vault:** A tabbed log viewer (INFO, DEBUG, TRACE) with:
  - **Individual Toggles:** Streams are paused by default to save browser resources.
  - **Auto-Pause:** A safety threshold that pauses the feed after 100 records to prevent DOM overload.
  - **Export Options:** One-click exports to `.json`, `.csv`, `.log`, and encrypted `.exolog` formats.
- **Copy Controls:** Added one-click clipboard buttons for the Node ID and live log excerpts.

## 2. Global UI Scaling (Accessibility)

To support diverse hardware and vision requirements, I implemented a global scaling listener in the ExoTalk Flutter app.

- **Keyboard Shortcuts:** Global interception of `Ctrl +` (Enlarge), `Ctrl -` (Shrink), and `Ctrl 0` (Reset).
- **Dynamic Text Scaling:** Adjusts the application's `TextScaler` across a range of 0.5x to 3.0x.
- **Unified Implementation:** Uses a Riverpod `StateProvider` and a `Focus` listener in `main.dart` to ensure the scaling applies instantly to every screen and widget.

## 3. Operational Documentation

I created the **[Conscia Operations Guide (docs/conscia_ops_guide.md)](../conscia_ops_guide.md)** which serves as the "SOP" for node operators, covering:
- The difference between `cargo run` (Dev) and standalone binary execution.
- How to "zap" new builds to remote laptops using `rsync`.
- Setting up **SSH Port Forwarding** for remote dashboard access.
- Establishing **Federation Handshakes** between distinct nodes.

## Verification
- [x] SSE streams correctly filter by level (INFO/DEBUG/TRACE).
- [x] Pause modal appears at 100 records and auto-dismisses after 10s.
- [x] Node ID copy button correctly captures the full cryptographic string.
- [x] Flutter UI scaling preserves layout integrity at 0.5x and 3.0x.
- [x] `conscia` binary build is fully self-contained.

![Conscia Dashboard with Live Telemetry](../conscia_health_check_1776554576557.webp)
