# Improvement Notes

## ⚙️ Performance & Efficiency
- **High Idle CPU Usage**: The Bridge Monitor app consumes 30-40% CPU even when idle. 
    - **Observed Behavior**: Resource usage drops to ~5% immediately upon closing the app.
    - **Hypothesis**: The combination of `Timer.periodic` telemetry polling (subprocess calls to `systemctl` and `pgrep`) and Flutter's rendering loop for animated indicators is inefficient.
    - **Proposed Research**: Quantify the impact of subprocess spawning vs. native C/FFI calls for process status. Evaluate if reducing the animation frame rate or using a "lazy" update model (only when in focus) reduces load.
    - **Goal**: Achieve <5% idle CPU while maintaining 1s telemetry accuracy.

## 🏷️ Naming Consistency
- **Unified Service Management**: We have successfully transitioned from "Kill Switches" to "Service Toggles" and "Conscia Tristate". The `BridgeNode` class could potentially be renamed to `ServiceNode` in a future refactor to reflect its broader role in managing systemd services.
