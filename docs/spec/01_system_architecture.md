# System Architecture

## 1. Sovereign Engine Workspace

The entire Exosystem is powered by a single Rust Cargo workspace (`exotalk_engine/`) that enforces strict app isolation to prevent bloat.

### Core
- **`exotalk_core`**: The agnostic P2P engine. Manages raw data synchronization (Willow), networking (Iroh), and cryptographic identity (Meadowcap). It has zero awareness of application-level data models.
- **Telemetry Sidecar**: A lightweight HTTP service (Port 11434) that exposes real-time engine state for automated verification and dashboard metrics.

### Pure Schemas (Data Shapes)
- **`exotalk_schema`**: Defines ExoTalk-specific structures (`DirectMessage`, `UserProfile`).
- **`republet_schema`**: Defines RepubLet-specific structures (`ScientificReport`, `Dataset`).
- **`exonomy_schema`**: Defines Exonomy-specific structures (`Voucher`, `MintedOffer`).
- **`exocracy_schema`**: Defines Exocracy-specific structures (`Project`, `TaskNode`).

### Independent FFI Bridges
Each Flutter application has its own isolated FFI bridge to guarantee that no foreign data models are compiled into the wrong app:
- **`exotalk_ffi`**: Binds `exotalk_core` + `exotalk_schema` → ExoTalk Flutter.
- **`republet_ffi`**: Binds `exotalk_core` + `republet_schema` → RepubLet Lite Flutter.
- **`exonomy_ffi`**: Binds `exotalk_core` + `exonomy_schema` → Exonomy Flutter.
- **`exocracy_ffi`**: Binds `exotalk_core` + `exocracy_schema` → Exocracy Lite Flutter.

### Shared Modules
- **`exoauth`**: A pure Flutter Dart package serving as the unified "Solid Front Door" for the entire Sovereign Exosystem. It provides the core identity UI (`WelcomeScreen`) and is consumed by all primary Exotalk applications via dependency injection to standardize the authentication workflow.

### Standalone Binaries
- **`conscia`**: A headless daemon/beacon providing 24/7 message persistence for the swarm.

## 2. Platform Matrix

| Technology | Applications | Rationale |
|---|---|---|
| Flutter (Mobile) | ExoTalk, Exocracy Lite, RepubLet Lite | Standardized feed/social UIs, compact mobile-first layouts |
| Flutter (Desktop/Web) | CMC, Exotalk, Exocracy Flutter, RepubLet Flutter, Exonomy Flutter | High-density grids, Gantt charts, complex telemetry, and node management |

## 3. UI System Architecture

All Flutter applications utilize a unified **Solid Identity** design system implemented in `ExoTheme`. 

- **Theme-Awareness**: A context-aware design token system ensures that the UI dynamically responds to Tristate Theme switching (Light/Dark/System) across all components.
- **Visual Consistency**: High-density horizontal layouts and tactile feedback loops are standardized to ensure a professional, sovereign feel throughout the exosystem.
