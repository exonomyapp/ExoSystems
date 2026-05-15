# Walkthrough 10: Monorepo Evolution & Engine Decoupling

This document records the architectural transition from a single application to a multi-application ecosystem.

## Ecosystem Evolution

Originally, the Rust P2P engine (Willow/Iroh capabilities) was coupled to the ExoTalk user interface. 

The engine was decoupled to allow identity, data management, and decentralized routing to serve as a shared layer for multiple applications.

### Step 1: The `exotalk_engine` Workspace
The Rust code was extracted from the Flutter project and moved to the root of the repository as `exotalk_engine/`, converted into a Cargo Workspace.

The workspace is divided into specific domains:
1.  **`exotalk_core`**: Contains cryptography, networking, and the Willow database.
2.  **`rust_lib_exotalk_flutter` (FFI Bridge)**: A wrapper around `core` using `flutter_rust_bridge` to provide logic to Dart for mobile and desktop applications.
3.  **`conscia`**: A standalone daemon binary that imports `core` to act as a relay node in the mesh.

### Step 2: Build System Resilience (The "RealPath" Fix)
Moving the engine necessitated updates to the build process to resolve physical paths within the monorepo, bypassing issues with Flutter's internal symlink structure. A `REALPATH` resolution strategy was implemented in `CMakeLists.txt`, `build.gradle`, and podspecs.

### Step 3: Repository Optimization
The `google-cloud-sdk` was moved to a peer directory (`../google-cloud-sdk`) to reduce repository size. Deployment scripts (`infra/gcp_push.sh` and `infra/gcp_bootstrap.sh`) were updated to resolve the SDK path dynamically.

---

## Implementation of RepubLet

Decoupling the engine enabled the development of distinct applications on the same infrastructure. 

**RepubLet** was introduced as a scientific publication platform for decentralized data distribution.

RepubLet utilizes a **Bi-Platform Architecture**:

1.  **`republet_web` (Desktop)**: A SvelteKit frontend wrapped in Tauri. `republet_desktop` was added to the `exotalk_engine` Cargo workspace, allowing it to use `exotalk_core` directly.
2.  **`republet_lite` (Mobile)**: A Flutter app that reuses the `rust_builder` FFI bridge.

### Shared Identity Implementation
Applications compiling against the same engine share the same local Identity Vault. Identity, cryptographic keys, and data history are shared across the application suite.
