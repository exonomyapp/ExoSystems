# ExoTalk (Multi-Platform)

[ Back to Root ](../README.md)

This is the decentralized chat application. 

ExoTalk compiles natively for iOS, Android, macOS, Linux, and Windows using Flutter. It does not rely on a centralized backend.

## Onboarding
ExoTalk features a "Link or Generate" onboarding flow:
*   **Google & GitHub**: Link social identity to a local `did:peer`.
*   **Conflict Resolution**: Notification system for identity reconciliation.
*   **Isolation Mode**: Each profile has separate storage and P2P lifecycle.

## Account Manager
The Account Manager is a two-column modal (`maxWidth: 920`) that contains identity and security controls:

*   **Profile Section**: Avatar tile with change/remove photo options. Contains the **Display Name** editor and **Network Sync** controls (Inbound/Outbound toggles).
*   **Security**: DID identifier and signing secret. The **"Generate"** action recreates the Ed25519 keypair via Rust FFI.
*   **Verified Identities**: Carousel of linked social proofs. Each tile provides "View Proof" and "Remove Link" actions.
*   **Activation**: The primary action button transitions between **"Initialize Identity"** and **"Sync Account"**.
*   **Pairing Action**: The "Pair" button in the Network Sync header opens the QR-code pairing flow for cross-device identity migration.
*   **Tristate Theme Support**: Integrated appearance control for Light, Dark, and System modes. 
*   **Danger Zone**: Full-width destructive action row for "Discard Identity" (local-only wipe).

All interactive tiles use a unified `_MenuButton` with `AnimatedScale` tactile press feedback (0.96×). The interface uses opaque surfaces and high-contrast borders.

## Mesh Traffic & Node Management
The Home Screen features a traffic visualizer and node management tools:
*   **Real-Time Feedback**: Scrolling bar charts that reflect activity when peers are detected on the mesh.
*   **Status Integration**: Meters transition between "Searching..." (0 peers) and "Mesh Active" states based on the node status.
*   **Node Management**: A section for managing a set of nodes.
    - **Live Roster**: Dynamic polling of the associated mesh roster.
    - **Capability Management**: Viewing and delegation of capabilities (Reader, Writer, Admin) per node.
    - **Integration**: Selecting a node switches the main view to a specialized Node Management dashboard.
*   **Independent Gating**: Inbound and Outbound lanes reflect synchronization preferences and mesh visibility.

## Architecture
ExoTalk's UI is written in Dart/Flutter. Networking, state synchronization, and cryptography are processed by the Rust engine.

We use `flutter_rust_bridge` to generate the binding code. This application links to `../exotalk_engine/exotalk_ffi/` which contains the logic for chat interfaces.

## Development

### 1. The Rust Builder
The core Rust logic is compiled and linked via the **[Rust Builder](rust_builder/README.md)**. Refer to its README for toolchain and Cargokit details.

### 2. Generating the Bridge
If you make a change in the `exotalk_ffi` Rust crate, you must regenerate the Dart bindings:
```bash
flutter_rust_bridge_codegen generate
```

### 3. Generating the Riverpod State
We utilize `riverpod_generator`. When adding new state providers or JSON serialization models, run:
```bash
flutter pub run build_runner watch -d
```

### 4. Launching
```bash
flutter run
```

## Accessibility & UI Scaling
ExoTalk supports global UI scaling.
- **Ctrl +**: Enlarge UI (up to 3.0x)
- **Ctrl -**: Shrink UI (down to 0.5x)
- **Ctrl 0**: Reset to 1.0x (Default)

This scaling applies to all screens, fonts, and icons.
