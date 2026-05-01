# ExoTalk Development Guidelines

This document outlines the core principles and UI/UX standards for the ExoTalk decentralized P2P messaging application.

> [!IMPORTANT]
> These guidelines are a local implementation of the global **[Exosystem Standards](exosystem-standards.md)**. All cross-project technical and aesthetic decisions are managed in that central record.

## 1. Identity & Account Management
- **Naming**: Always use "Account Manager" for the user profile interface.
- **Key Rotation**: Generating new peer keys creates a fresh identity (DID). This should be clearly explained as a "reset" of the user's persona on the mesh.
- **Verification**: The "Verify" action binds a human-readable display name to a DID via a cryptographic signature.
- **Private Key Security**: Root secrets (Signing Secrets) must be visually distinguished with warnings and professional vault styling, as they are the sole proof of identity.

## 2. Typography & Styling
- **No All-Caps**: Strictly use sentence case for all labels, buttons, and UI text. No `uppercase` or `tracking-widest` utility classes.
- **Unified Button Styling**: Buttons in the same functional group (e.g., Verify and Rotate) must have identical styling (variant, height, weight).
- **Hover Contrast**: Hover states must maintain high contrast; font colors must not become indistinguishable from the background color.

## 3. UI/UX Standards
- **Explanations**: No "hanging" or "mid-air" labels for info. Use verbose, professional tooltips attached directly to the relevant buttons.
- **Responsive Width Clamping**: All top-level `Dialog` or `Modal` containers must use responsive width clamping to prevent "Expansion Walls."
    - Pattern: `maxWidth: (MediaQuery.of(context).size.width * factor).clamp(min, max * scale)`
    - Pattern (High-Density): `(MediaQuery.of(context).size.width * 0.95).clamp(800.0, 1100.0 * scale)`
    - This ensures modals remain legible on ultrawide monitors while providing adequate density on smaller displays.
- **Modal Constraints**: Tooltips and popovers must be positioned to stay fully within the visible 2D boundaries of the modal.
- **Avatar Management**: Support three interaction methods: manual URL input, clicking the avatar to load a local file, and dragging-and-dropping an image directly onto the avatar space.

## 4. Interaction Integrity
- **Focus Management**: Ensure `DropdownMenu` triggers release focus properly before opening `Dialog` components to prevent UI lockups.
- **Backdrop Cleanup**: Clicking outside a modal must correctly unlock the browser's interaction layer and return control to the UI.

## 5. Conscia & Commercial Interactions
- **The Conscire Action**: The "Conscire" button is the gateway to commercial reporting. It must be styled with a "Premium" variant (e.g., subtle gold or deep emerald accents) to distinguish it from standard "Lifeline" chat actions.
- **Service Agreements**: Entering a Conscire agreement must be preceded by a clear, professional disclosure modal that explains the transition from a free anonymity-first chat to a commercialized data reporting environment.
- **Reporting UI**: Any data visualizations provided by the Conscia service must follow the same "No All-Caps" and high-contrast rules, maintaining the ExoTalk aesthetic while providing denser informational displays.

