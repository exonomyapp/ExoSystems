# ExoTech Bridge Monitor

The **ExoTech Bridge Monitor** is a diagnostic dashboard built to monitor the health and connectivity of the infrastructure.

Unlike the core Conscia daemon or the Exonomy application, the Bridge Monitor is a utility designed for live demonstrations and system-level verification.

## Features
- **Dynamic Discovery**: Automatically scans for and identifies local nodes (Signaling Relay on port 8080, Conscia Beacon on port 3000, and Public zrok Proxy).
- **Aesthetics**: Uses high-contrast, low-glare themes optimized for diagnostic monitoring.
- **Dual Display Modes**: Toggles between Card views and List views for use in different display environments.
- **Interactive Service Control**:
    - **Signaling & Zrok**: Binary ON/OFF toggle via `systemctl --user`.
    - **Conscia Beacon**: 3-state Tristate Toggle (ON/SLEEP/OFF) implementing the Observer Model.
- **KDVV Protocol**: Keyboard shortcuts (1/2/3/t/v/r) enable remote automation via `xdotool` for deterministic testing.
- **Click Logging**: All Conscia toggle interactions are logged to `~/bridge_monitor_clicks.log` for remote programmatic verification.

## Deployment

The Bridge Monitor is compiled on the **Exocracy** workstation and deployed to the **Exonomy** laptop via `scp`:

```bash
# Build on Exocracy
cd infra/bridge_monitor && flutter build linux --release

# Deploy to Exonomy
sshpass -p '.' scp -r build/linux/x64/release/bundle/* \
  exocrat@exonomy.local:/home/exocrat/code/exotalk/infra/bridge_monitor/build/linux/x64/release/bundle/
```

The Exonomy desktop icon (`~/Desktop/exotech_bridge.desktop`) points to the release bundle path.

## Documentation

For coverage of how this Bridge Monitor integrates with the `exotalk.tech` Wasm emulation and the underlying services running on the Exonomy node, refer to the following walkthroughs:

- **[Walkthrough 46: ExoTech Bridge & Infrastructure Stabilization](../../docs/walkthroughs/46_exotech_bridge_and_infrastructure_stabilization.md)**
- **[Walkthrough 49: Conscia Toggle Stabilization & Deployment Protocol](../../docs/walkthroughs/49_conscia_toggle_stabilization_and_deployment_protocol.md)**
