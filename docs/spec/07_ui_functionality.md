# UI Functionality Features

- **Sovereign Sidebar (Left Panel):**
  - **Header**: Navigation hub containing the collapse toggle and persona status.
  - **Search**: Integrated connection search bar.
  - **Connection List**: Vertical list of active secure channels with presence indicators.
  - **Footer Controls**: Quick access to Flight Mode, Theme Tristate, and Account Settings.

- **Account Manager Modal:**
  - **Symmetrical 50/50 Layout**: The modal is split into a strict two-column grid to maximize density and avoid scrolling.
  - **Header Row**: Profile (Avatar/Name) on the left, Network Sync (Toggles/Pair) on the right.
  - **Body Row**: Security Vault (DID/Secrets) on the left, Verified Identities (Carousel) in the middle, and Conscia Lifeline (Node ID/Request Access) on the right.
  - **Danger Zone**: Full-width destructive action row for "Discard Identity" (permanent local wipe).
  - **Interaction Model**: All interactive tiles use `_ConsciaMenuButton` with tactile press feedback (0.96×) and context menus.
  - **Keyboard Shortcuts**: Supports `Ctrl+Enter` or `Ctrl+S` for Sync, and `Escape` for Cancel/Close.

### 7.2 Keyboard-First Automation
The interface is designed for high-determinism automation to support headless P2P federation testing.
- **Welcome Screen**: `Enter` or `Space` triggers the onboarding menu. The "Get Started" button is `autofocus: true` to allow immediate programmatic interaction.
- **Modals**: Global `CallbackShortcuts` ensure that all critical dialog actions (Sync, Confirm, Cancel) are reachable via standard keyboard events, eliminating reliance on pixel-coordinate mouse clicks.

### 7.3 Sovereignty Drawer
The Sovereign Sidebar is the primary navigation and control hub.
- **Resizability**: Users can drag the right edge to adjust sidebar width (200px - 600px). State is persisted across sessions.
- **Collapsibility**: The sidebar can be collapsed to a minimal state to maximize workspace area.
- **Quick Controls**: Flight Mode, Theme Tristate, and Account Settings are pinned to the sidebar footer.

### 7.4 Mesh Metering
- **High-Fidelity Telemetry**: Inbound (Ingress) and Outbound (Egress) traffic are visualized as independent, smoothly scrolling meters.
- **Connection Awareness**: Meters pulse with activity only when active peers or a Conscia Lifeline connection are detected.
- **Searching State**: When disconnected, meters show a "Searching..." / "Awaiting peer..." state with a flatlined visual.
- **Flight Mode**: A global "MESH PAUSED" warning appears when all traffic is gated.

- **Group Manager:** Handles shared namespaces for group chats, reflecting Meadowcap delegations.
- **Chat Window:** Real‑time materialized view synced from the Willow master store, supporting inline media.

### 7.5 Conscia Fleet Management
ExoTalk includes a native sidebar-integrated interface for managing a user's network of associated Conscia nodes.
- **Dynamic Node List:** A collapsible "Conscia Nodes" group in the sidebar displays a live roster of discovered peers, polled from the Rust engine.
- **Integrated Actions:** A "+" action in the expansion header allows for frictionless node association (did:peer association).
- **Context-Aware Dashboard:** Selecting a node loads a specialized `NodeManagementView` in the main content area. This view dynamically evaluates and displays:
  - **Live Connectivity:** Real-time connection status (Connected/Unreachable).
  - **Peer Addresses:** List of known network addresses for the node.
  - **Meadowcap Capabilities:** Displays active delegations (e.g., WRITER role) and provides controls for capability grant and revocation.
- **Capability Governance:** The UI enforces the principle of least privilege, presenting only the control options the current user possesses over each specific node.

### 7.6 Sovereign Technical Footer
The sidebar includes a high-density environment dashboard below the Account Settings gear.
- **Visual Style**: Monospace, small-font telemetry blocks aligned to a strict grid.
- **Refresh Rate**: 500ms for high-priority traffic pulses.
- **Data Points**:
    - **Layer 1 (Net)**: Local IP & Port, Home Relay URL.
    - **Layer 2 (ID)**: Node ID (truncated), Uptime, Clock Drift.
    - **Layer 3 (Mesh)**: Blob Store Size, Traffic Pulse (Ingress/Egress).
    - **Layer 4 (Env)**: OS/Architecture, Process ID (PID).
+
+### 7.7 Terminal Interaction Protocol (CLI/TUI)
+For headless nodes and power users, the system employs a tiered terminal strategy:
+- **Tier 1: CLI (`clap`)**: Non-interactive automation, piping, and quick commands (e.g., `conscia status`).
+- **Tier 2: Interactive (`inquire`)**: Guided onboarding, configuration wizards, and confirmation prompts.
+- **Tier 3: TUI (`ratatui`)**: Immersive, full-screen dashboard for real-time monitoring of mesh health and logs in a terminal environment.
