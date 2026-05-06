# Walkthrough 62: Bridge Monitor v1.3.0 "Legislator" Update

The Bridge Monitor has been fundamentally upgraded to **v1.3.0-LEGISLATOR**, shifting to a high-efficiency GPU-accelerated architecture, adopting strict Tristate service legislation across all nodes, and establishing a premium aesthetic baseline.

## Changes Made

### 1. GPU-Accelerated Heartbeat Engine (Fragment Shaders)
- Replaced the CPU-heavy `AnimationController` and `Opacity` masking with a dedicated GLSL Fragment Shader (`heartbeat.frag`).
- The sine-wave pulse math and alpha masking are now calculated per-pixel by the GPU via `CustomPainter` and `FragmentProgram`, vastly reducing main thread Flutter overhead.

### 2. Hybrid Adaptive Ticker (30Hz/5Hz)
- Implemented an intelligent `_scheduleNextTick()` polling engine.
- When any node is active (Up and not Sleeping), the ticker operates at 30Hz (`33ms` interval) to feed the shader the `u_time` uniform for smooth breathing animations.
- When all nodes are Sleeping or Off, the ticker automatically throttles down to 5Hz (`200ms` interval), eliminating unnecessary CPU wakeups.

### 3. Universal "Legislator" Control Flow
- Removed the binary `CupertinoSwitch` widgets from the UI.
- Standardized all nodes (Signaling Relay, Conscia Beacon, Public Proxy) to use the deterministic Tristate `CupertinoSlidingSegmentedControl` (ON, SLEEP, OFF).
- The Bridge Monitor now acts as the authoritative "Legislator," issuing direct `systemctl --user` commands to orchestrate background daemons directly.

### 4. UI First-Class Citizenship & Contrast Hardening
- **Desktop Icon**: Restored `exotalk_pappus_desktop.png` as the primary application header logo and updated the `.desktop` launcher shortcut to utilize this exact asset.
- **Glassmorphism HUD**: Promoted the HUD into a distinct, semi-transparent container component with borders and shadow, giving it a premium, integrated feel.
- **Light Mode Rebalancing**: Swapped the header background to a lighter `0xFFE1E4E8` to enhance asset visibility, moved the robust "Dashboard Gray" (`0xFFAEB2B8`) to the scaffold background, and hardened node subtitles to `black87` for maximum contrast.

## Validation Results
- Local compilation (`flutter build linux --debug`) succeeded with zero errors.
- The release bundle was successfully built and deployed via SSH/SCP to the Exonomy target.
- The Exonomy desktop shortcut (`exotech_bridge.desktop`) was dynamically updated to point to the `desktop` variant of the icon and granted execution permissions.
- Scrot debris was successfully cleaned up per housekeeping protocols.
