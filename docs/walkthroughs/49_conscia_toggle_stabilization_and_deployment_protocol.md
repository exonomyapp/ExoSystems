# Walkthrough 49: Instrumented Service Lifecycle Control & Performance Audit

This walkthrough documents the stabilization of the Bridge Monitor's interactive controls, the formalization of the "Service Toggle" architecture, and the identification of a CPU usage regression.

## Root Cause Analysis (Conscia Toggle)

### The Problem
When activating the Conscia Tristate Toggle on Exonomy, the toggle state would revert immediately to OFF and become unresponsive.

### The Fix
1. **Absolute Binary Path**: Replaced `cargo run` with the absolute path to the pre-compiled binary, eliminating PATH dependency issues.
2. **State Guards**: Wrapped state transitions in a `try/finally` block to ensure the `_isProcessing` guard is reset.
3. **Unified Code Paths**: Synchronized keyboard and mouse handlers to utilize the same logic and binary path.

## Naming & Instrumentation Updates

Technology transitioned from emergency controls to **Instrumented Service Lifecycle Control**:

- **NodeKillSwitch** to **NodeServiceToggle**: Reflects service control (Signaling/Proxy) via `systemctl`.
- **Instrumentation**: Added timestamped click logging to `~/bridge_monitor_clicks.log` for verification.
- **Node IDs**: Renamed `beacon-1` to `conscia-1` for architectural clarity.

## Performance Audit: 1s Refresh & CPU Load

### Polling Frequency
The telemetry polling interval was reduced to 1 second to provide feedback for service changes.

### CPU Usage Regression
During testing, the Bridge Monitor consumed 30-40% CPU when idle.
- **Analysis**: The overhead is attributed to high-frequency subprocess spawning (`systemctl`, `pgrep`, `tail`) required for telemetry. Optimization is required.

## Document Checklist

| File | Status |
|---|---|
| `infra/bridge_monitor/lib/main.dart` | Renamed components, 1s refresh, state guards, logging. |
| `infra/bridge_monitor/README.md` | Updated features and deployment documentation. |
| `docs/spec/telemetry_verification.md` | Updated to reflect polling intervals and binary paths. |
| `improvement_notes.md` | Captures CPU profiling goals. |

## Deployment Status

- **Build**: `flutter build linux --release`
- **Transfer**: Release bundle deployed via `scp`.
- **Verification**: Click logging verified for nodes.

## Strategic Decision: Asset Management

The repository's media assets reached ~55MB. Three scaling strategies were evaluated:

1.  **Git LFS (Large File Storage)**: Replaces binaries with text pointers.
2.  **Separate Assets Repository (Selected)**: Moving media to a dedicated repository and referencing them via URLs.
    - **Rationale**: Aligns with the Triad architecture of modular independence and maintains core repository efficiency.
3.  **Third-party hosting**: Not suitable for production-grade infrastructure documentation.

**Decision**: Implementation of a separate media repository to maintain core repository focus on logic.lay using the stabilized monitor.

