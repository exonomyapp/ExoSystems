# Specification 17: Solid Front Door Standard

## Overview
The "Solid Front Door" is the architectural standard for the primary authentication and entry-point UI across the ExoTalk ecosystem. It prioritizes structural stability, visual density, and modular scalability to ensure a consistent, premium experience across all decentralized applications.

## 1. Structural Guardrails (The "Non-Elastic" Frame)
To prevent the "rubber-band" distortion common in early responsive web design, the Front Door follows strict horizontal constraints:

### 1.1 Minimum Width (The Floor)
- **Constraint**: `minWidth: 440px` (scaled).
- **Rationale**: Any compression beyond this point compromises the legibility of Authorial Identity cards and the primary "Get Started" triggers.
- **Behavior**: If the viewport narrows beyond this threshold, the application MUST enable a horizontal scrollbar rather than compressing the internal UI elements. This preserves the "Persona" layout integrity.

### 1.2 Button Stability (The Anchor)
- **Constraint**: `maxWidth: 320px` (scaled).
- **Rationale**: Primary action buttons (Get Started, Identity switchers) must maintain fixed, predictable proportions. 
- **Behavior**: Even if the parent UI frame expands on large monitors, the interactive elements remain anchored at their stable maximum width to prevent them from feeling "stretched" or amateur.

## 2. Information Density
The Front Door standard mandates a high-density typographic hierarchy to maximize visible context on the first screen.
- **Vertical Padding**: Spacing between the icon, header, and primary identity blocks is minimized (8px–12px) to keep the core "Personas" above the fold.
- **Centering**: All text elements, labels, and icons MUST be horizontally centered within the card frame to maintain formal balance.

## 3. Modular OAuth Scalability
The "Exoauth" pattern enables unlimited authentication providers without vertical clutter.

### 3.1 The 2-Button Rule
- **Logic**: Only the top two (2) primary providers are displayed in the initial view.
- **Grid Placement**: Providers are laid out in a symmetrical 2-column grid.

### 3.2 The Graphical Accordion
- **Logic**: Any providers beyond the primary two (overflow) are moved into a collapsible "More Options" component.
- **Rationale**: This prevents the "wall of buttons" anti-pattern and ensures the UI frame never requires vertical scrolling on standard desktop resolutions.

## 4. Implementation (Exoauth)
The Front Door is implemented as a shared Flutter package (`exoauth`).
- **Path**: `code/exotalk/exoauth`
- **Consumption**: All ecosystem apps (`exotalk_flutter`, `republet_lite`, `conscia_flutter`) MUST consume this package via local path dependency to ensure 100% parity across the mesh.

## 5. Typography and Aesthetics
- **Brightness Tuning**: To reduce eye strain and provide a more balanced "Dark Mode" aesthetic, the primary white text elements (headers, body text, primary button text) are toned down to an 80% intensity (e.g., using an `0xCC` alpha channel or equivalent toned-down hex) rather than pure white. This prevents the text from being overwhelmingly bright against the deep dark surfaces.

## 6. The First-Run Lifecycle (Onboarding)

The transition from binary acquisition to **Identity Synthesis** must be frictionless and narrative-driven.

### 6.1 The Welcome Pulse
The very first screen utilizes a high-fidelity animated splash screen reflecting the node's heartbeat. If no identity is detected, the app initiates the "Universal Passport" sequence.

### 6.2 Identity Synthesis (The "Familiar Front Door")
- **OAuth Bridge**: To bridge the gap for users familiar with Google/Apple sign-in, the system facilitates identity creation *through* these providers.
- **Synthesis Logic**: During the familiar OAuth flow, a `did:peer` is generated locally and cryptographically associated with the provider's token. The user feels the comfort of a standard login, while the mesh receives an independent P2P identifier.
- **Independent Path**: A "Raw P2P" path remains available for power users to generate an unanchored `did:peer` in two taps.

### 6.3 Conscia Pairing & Mesh Discovery
- **Pairing**: New installs are encouraged to link a **Conscia Lifeline** node for persistent data storage.
- **Discovery**: An automatic local network scan (mDNS/Bluetooth) immediately shows P2P connectivity potential to "WOW" the user with the scale of the mesh.
