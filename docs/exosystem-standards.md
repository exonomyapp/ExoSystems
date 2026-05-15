# Exosystem: Development Standards

This document serves as the central "Master Record" for all technical, aesthetic, and operational standards within the Exosystem. All applications (ExoTalk, RepubLet, Exonomy, Exocracy) must adhere to these guidelines to ensure a unified user experience and architectural resilience.

## 1. UI/UX & Aesthetics (The Conscia Standard)

The Exosystem aesthetic is premium, high-visibility, and high-performance.

### Visual Identity
- **Palette**: Deep dark backgrounds (`#0D1117`), high-contrast surfaces (`#161B22`), and "Exosystem Green" accents (`#238636`).
- **Glassmorphism**: Use `backdrop-filter: blur()` and semi-transparent layers for headers, sidebars, and overlays to create visual depth and hierarchy.
- **Aesthetic Excellence**: Avoid browser defaults. Use modern typography (e.g., 'Inter', 'Outfit'), smooth gradients, and subtle micro-animations (e.g., "glow" effects on active states).

### Layout Logic (The fantasai Principles)
- **Logical Properties**: Prioritize **Logical Properties** over physical ones to support global writing modes. Use `inline-start/end` and `block-start/end` instead of `left/right/top/bottom`.
- **The Grid-First Standard (Flutter)**: Legacy `Row` and `Column` widgets are deprecated for primary component structures. All structural layouts must use the `LayoutGrid` package to define deterministic track sizes (`auto`, `1.fr`) and explicit `GridPlacement`. This eliminates "vibrating edges" during complex animations and window resizing.
- **Content-Driven Sizing**: Layouts must be robust. Use CSS Grid or `LayoutGrid` with `min-content`, `max-content`, and `auto-fit` to ensure components respect their content's physical requirements without breaking.
- **Subgrid Alignment**: Use `subgrid` (or shared grid track patterns in Flutter) for nested layouts to maintain horizontal and vertical alignment "truth" across independent components.

## 2. Interaction & Accessibility

### UI Scaling (Fluidity Standard)
- **Granularity**: Zoom increments must be subtle (0.05x steps) to provide a smooth user experience.
- **Range**: All interfaces must be functional and visually coherent from **0.5x to 4.0x** scale.
- **Robustness**: Components must use relative units or flexible layout widgets to prevent overlapping or clipping at extreme scales.

### Scale-Aware Components
- **Proportional Scaling**: Static UI elements (icons, switches, checkboxes, and specific paddings) must scale proportionally with the application's zoom factor.
- **Transformations**: Use transformations (e.g., `Transform.scale` in Flutter) or relative factor multiplication for widgets with fixed intrinsic sizes to avoid "Dinosaur" or "Ant" components at extreme zoom levels.
- **Contrast & Visibility**: Secondary text and icons must maintain high visibility. Interactive icons must use primary text colors (not muted) when clarity is prioritized.

### Appearance & Theming
- **Tristate Toggle**: Every application must provide a clearly accessible **Tristate Toggle** for theme selection:
    1.  **Light Mode**: Standard high-contrast light theme.
    2.  **Dark Mode**: The primary Conscia-style dark theme.
    3.  **System Mode**: Automatically follows the host operating system's theme preference.
- **Default State**: Applications should default to **System Mode** on first run.
- **Persistence**: The user's selection must be persisted locally in the Identity Vault to ensure consistency across sessions.
### Text & Semantic Integrity
- **Sentence Case**: Strictly use sentence case for all buttons, labels, and titles. **No All-Caps** styling.
- **Professionalism**: Avoid "hanging" labels. Use verbose, professional tooltips and inline explanations for complex cryptographic actions.

## 3. Identity & Security Presentation

### The Identity Vault
- **Visual Distinction**: Private keys, signing secrets, and root identities must be styled with distinct "Vault" aesthetics (e.g., deep backgrounds, monospaced fonts, and explicit security warnings).
- **Security Warnings**: Any action that risks identity loss (e.g., key rotation) must be preceded by a professional disclosure modal.

### Commercial Transitions
- **Conscire Interactions**: Actions that transition the user from free anonymity to commercialized reporting (the "Conscire" action) must be styled with premium variants (e.g., gold or emerald accents) to signify a change in the data-autonomy contract.

## 4. The Agent Protocol (Operational Excellence)

- **Educational Transparency**: All code modifications must include qualitative comments explaining the rationale. No "stealth" logic changes.
- **User Agency**: The AI agent operates only with explicit user approval for file-modifying or system-level actions.
- **Centralized Control**: Standards documented here are the source of truth for all automated and manual development.
