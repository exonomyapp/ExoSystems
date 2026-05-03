# Spec 29: KDVV Remote Control Protocol

This specification defines the standard for **Keystroke-Driven, Visual-Verified (KDVV)** remote orchestration used by the AI agent to manage, diagnose, and automate the Exosystem mesh.

## 1. Philosophy: Programmatic Humanity

To ensure that the AI agent can verify infrastructure health with the same efficacy as a human operator, the application must expose hidden "Agent Mode" hooks. These hooks allow for deterministic state transitions that are visually verifiable via screenshots.

- **Non-Intrusive**: Diagnostic features must not clutter the UI for the end-user unless explicitly activated.
- **Visual Feedback**: Every remote command must produce a corresponding visual change (HUD updates, color shifts, or rainbow borders).
- **Deterministic Latency**: Commands must be processed within a fixed time window (500ms) to allow for synchronized screenshot capture.

## 2. Standard Diagnostic Keys

The following keys are ubiquitously mapped across the Bridge Monitor suite:

| Key | Action | Visual Confirmation |
|-----|--------|---------------------|
| **`d`** | Toggle Repaint Rainbow | Multi-colored flashing borders on repainting widgets. |
| **`h`** | Toggle Agent Mode (HUD) | Purple "AGENT MODE" HUD appears in the header. |
| **`r`** | Full Data Reset | Log buffers clear; Build Count resets to 0. |
| **`s`** | Surgical Burst | Polling interval accelerates to 500ms for 10 cycles. |
| **`1`** | Toggle Signaling | Signaling health indicator shifts (Red/Green). |
| **`2`** | Cycle Conscia State | Conscia dot cycles (Red -> Orange -> Green). |
| **`3`** | Toggle Proxy | Proxy health indicator shifts (Red/Green). |

## 3. Polling & Verification Standards

To balance CPU performance with diagnostic precision, the Bridge Monitor implements a **Dynamic Throttle**:

- **Background Mode (Steady State)**: Polling occurs at **1000ms (1s)** intervals.
- **Active Mode (Transition)**: Polling accelerates to **500ms** immediately upon detecting a state change or receiving a Surgical Burst command (`s`).
- **Back-off**: After 10 consecutive steady states (no changes detected), the engine automatically returns to Background Mode.

## 4. Remote Execution Protocol (Exocracy -> Exonomy)

1. **Activate Window**: `xdotool search --name "ExoTech Bridge" windowactivate --sync`
2. **Inject Key**: `xdotool key [key]`
3. **Capture Result**: `scrot -z /tmp/verification.png`
4. **Audit**: The agent performs OCR or visual comparison of the "BUILD COUNT" and "AGENT MODE" HUD.

## 5. Security Note
These diagnostic keys are only active when the application is compiled in `debug` mode or when a specific `AGENT_MODE_ENABLED` flag is set in the environment.
