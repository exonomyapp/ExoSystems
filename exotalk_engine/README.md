# ExoTalk Engine Workspace

[ Back to Root ](../README.md)

This is the core logic of the ExoTalk application. It handles cryptography, peer-to-peer networking (via Iroh), and offline-first database syncing (via Willow).

## Workspace Domains

The engine is modularized into specific domains:

### 1. The Core
*   **`exotalk_core`**: The synchronization engine. It handles generic data synchronization across the network.

### 2. Data Schemas
These crates contain the specific data formats (structs) for different domains.
*   **`exotalk_schema`**: Stores the definitions for `DirectMessage`, `UserProfile`, etc.
*   **`republet_schema`**: Stores definitions for `ScientificReport`, `Dataset`, etc.
*   **`exonomy_schema`**: Stores definitions for `Voucher`, `MintedOffer`, `ExchangeRequest`, etc.
*   **`exocracy_schema`**: Stores definitions for `Project`, `TaskNode`, `VoucherAttachment`, etc.

### 3. FFI Bridges (Foreign Function Interfaces)
These crates bind the `exotalk_core` to specific `schema` crates and expose them to Flutter.
*   **`exotalk_ffi`**: Merges generic core bytes with `exotalk_schema` for the ExoTalk app.
*   **`republet_ffi`**: Merges generic core bytes with `republet_schema` for the RepubLet Lite app.
*   **`exonomy_ffi`**: Merges generic core bytes with `exonomy_schema` for the Exonomy Wallet app.
*   **`exocracy_ffi`**: Merges generic core bytes with `exocracy_schema` for the Exocracy Lite app.

### 4. Tauri Desktop Backends
These crates bypass FFI and use `exotalk_core` as a native Rust library.
*   **`republet_desktop`**: The Rust backend for the RepubLet SvelteKit desktop app.
*   **`exocracy_desktop`**: The Rust backend for the Exocracy SvelteKit desktop app.

### 5. Standalone Binaries & Wasm
*   **`conscia`**: A headless daemon designed to run on a Linux server to act as a relay node routing traffic between peer devices.
*   **[`exotalk_wasm`](exotalk_wasm/README.md)**: The WebAssembly core for browser-based sessions.

## Building
To verify all workspace components compile:
```bash
cargo check --workspace
```
