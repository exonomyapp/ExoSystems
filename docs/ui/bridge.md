# UI Specification: ExoTech Bridge Monitor

This document defines the architectural and interactive patterns for the ExoTech Bridge Monitor, a high-density diagnostic dashboard for the Exosystem.

## 1. Layout Philosophy: Single Row / Vertical Modules

Aligning with the "Solid Identity" mandate and high-density interface principles, the Bridge Monitor header adopts a **Single Row / Vertical Modules** approach anchored by a 96px matrix.

### 1.1 Header Structure (96px Geometric Anchor)
The header operates as a single horizontal row, with all elements vertically constrained to the 96px height of the Pappus logo:

1.  **Identity & Branding (Left)**: Standardized 96px logo. "EXOTECH BRIDGE" title, followed by the local node hostname, and the active version (e.g., v1.5.0-BRIDGE) on its own dedicated line.
2.  **The System HUD (Center)**: A vertically stacked, solid (opaque) block containing real-time system metrics (Memory RSS, Interval, Steady State count).
3.  **Control Column (Right)**: A vertically aligned set of toggles (View Mode, Theme, Agent Oversight) scaled to 0.7x to perfectly match the 96px vertical height limit of the HUD.

## 2. Visual Language: The Moses Protocol

The Bridge Monitor uses a tri-state visual indicator system for all nodes:

-   🔴 **OFF (Red)**: Service is stopped. No background processes active.
-   🟠 **SLEEP (Yellow)**: Service is running but in a low-power, non-interactive state.
-   🟢 **ON (Green)**: 
    -   **Idle (Dark Green)**: Service is active but no network traffic detected.
    -   **Active (Neon Green)**: Service is active with established TCP connections. Uses a solid static neon color without shimmer to ensure 0% CPU idle efficiency.

## 3. Interaction Model

### 3.1 Keyboard-Driven, Visual-Verified (KDVV)
Functional verification is primary driven by global keyboard shortcuts:
- `1-3`: Signaling Control (OFF/SLEEP/ON)
- `4-6`: Conscia Control (OFF/SLEEP/ON)
- `7-9`: Zrok Control (OFF/SLEEP/ON)
- `T`: Theme Toggle
- `V`: View Toggle (Grid/List)
- `R`: Force Refresh
- `H`: Toggle Agent HUD
- `D`: Toggle Debug Paint

### 3.2 State Cycling (Click Actions)
Interaction with any Node Card or List Row acts as a massive, tactile button to cycle the underlying service state (ON -> SLEEP -> OFF). This ensures a standardized code path with the standard Tristate toggle, reinforcing the manual ingress control narrative established in the UI.

## 4. Technical Constraints
- **0% Idle CPU Goal**: Animation must be offloaded or highly optimized.
- **FFI Stability**: Must maintain strict Rust content hash alignment to prevent deployment crashes.
