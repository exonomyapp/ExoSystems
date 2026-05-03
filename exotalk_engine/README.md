# ⚙️ ExoTalk Engine Workspace

This is the pure beating heart of the Sovereign application Exosystem. It contains no UI logic, operating entirely on fundamental cryptography, peer-to-peer networking (via Iroh), and offline-first database syncing (via Willow).

## Workspace Domains

To prevent "App Bloat," this engine is strictly modularized into 12 isolated domains:

### 1. The Core
*   **`exotalk_core`**: The pure engine. It knows nothing about chat messages, scientific reports, vouchers, or project trees. It only synchronizes raw agnostic bytes across the internet.

### 2. Pure Data Schemas
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
These crates bypass FFI entirely and use `exotalk_core` as a native Rust library for maximum performance.
*   **`republet_desktop`**: The Rust backend for the RepubLet SvelteKit desktop app.
*   **`exocracy_desktop`**: The Rust backend for the Exocracy SvelteKit desktop app.

### 5. Standalone Binaries & Wasm
*   **`conscia`**: A headless daemon/beacon designed to run on a Linux server to act as an always-on relay node perfectly routing traffic between peer devices.
*   **[`exotalk_wasm`](exotalk_wasm/README.md)**: The WebAssembly core for browser-based Sovereign Sessions.

## Building
To verify all 12 isolated parts compile harmoniously:
```bash
cargo check --workspace
```
