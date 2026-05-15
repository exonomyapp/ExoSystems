# Walkthrough 13: Real-Time Telemetry & Global UI Scaling

The Conscia dashboard has been updated with a network health diagnostic system, and global scaling has been implemented in the ExoTalk Flutter application.

## 1. Network Health Telemetry

The Conscia dashboard monitors connectivity stages in real-time to facilitate diagnostic analysis of P2P connection states.

### Backend Diagnostic Implementation
- Refactored `exotalk_core/src/network_internal.rs` to retrieve telemetry from `iroh::Endpoint`.
- Implemented a `tracing_subscriber::Layer` to intercept engine logs and broadcast via JSON.
- Added an Axum SSE endpoint at `/api/logs/stream` for real-time log delivery.

### Dashboard UI Updates
- **Health Tracker**: A visualizer tracking Engine Initialization, Local UDP Binding, Relay Reachability, Peer Mesh Count, and Gossip Subscriptions.
- **Log Viewer**: A tabbed log viewer (INFO, DEBUG, TRACE) with:
  - **Level Filtering**: Independent toggles for log levels.
  - **Safety Threshold**: Automatically pauses the feed after 100 records to manage DOM resource usage.
  - **Export Capability**: Support for `.json`, `.csv`, `.log`, and `.exolog` formats.
- **Copy Controls**: Clipboard integration for Node ID and log excerpts.

## 2. Global UI Scaling

Implemented a global scaling listener in the ExoTalk Flutter application to support diverse display requirements.

- **Keyboard Shortcuts**: Integration for `Ctrl +` (Enlarge), `Ctrl -` (Shrink), and `Ctrl 0` (Reset).
- **Dynamic Text Scaling**: Support for `TextScaler` adjustments from 0.5x to 3.0x.
- **State Management**: Utilizes a Riverpod `StateProvider` and `Focus` listener in `main.dart` for immediate application across all screens.

## 3. Operational Documentation

Created the **[Conscia Operations Guide (docs/conscia_ops_guide.md)](../conscia_ops_guide.md)** covering:
- Differences between development and production execution.
- Binary deployment to remote nodes via `rsync`.
- SSH Port Forwarding for remote dashboard access.
- Establishing federation connections between nodes.

## Verification
- Verified SSE stream filtering by log level.
- Verified pause threshold and auto-dismissal.
- Verified Node ID clipboard functionality.
- Verified Flutter UI scaling integrity across the supported range.
- Verified self-contained `conscia` binary build.

![Conscia Dashboard with Live Telemetry](../conscia_health_check_1776554576557.webp)
