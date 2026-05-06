# Walkthrough 10: Monorepo Evolution & Engine Decoupling

*This document serves as the historical record of the architectural leap from a single application to a multiversal Sovereign Engine Exosystem.*

## 🦋 The Metamorphosis: From App to Exosystem

Originally, the Rust P2P engine (Willow/Iroh capabilities) lived inside `exotalk_flutter/rust`—it was a prisoner to a single user interface. 

To realize the true vision of Sovereign Computing (as detailed in `vision.md`), the engine needed to be decoupled. Identity, data autonomy, and decentralized routing should be a universal layer that any application can plug into, not a feature of a single chat app.

### Step 1: The `exotalk_engine` Workspace
We extracted the Rust code from the Flutter project and promoted it to the root of the repository as `exotalk_engine/`. We then converted it into a true Cargo Workspace.

This workspace was divided into strict domains:
1.  **`exotalk_core`**: The pure beating heart. It contains all cryptography, networking, and the Willow database. It knows *nothing* about UIs.
2.  **`rust_lib_exotalk_flutter` (FFI Bridge)**: A thin wrapper around `core` using `flutter_rust_bridge`. It translates the core logic into Dart for mobile/desktop Flutter apps.
3.  **`conscia`**: A headless, standalone daemon binary that imports `core` to act as an always-on relay node in the mesh.

### Step 2: Build System Resilience (The "RealPath" Fix)
When we moved the engine out of Flutter, Flutter's ephemeral build process (which uses massive networks of temporary symlinks via `.plugin_symlinks`) broke. 

To fix this, we performed "Educational Commenting" across the `rust_builder` `CMakeLists.txt`, `build.gradle`, and podspecs. We implemented a `REALPATH` resolution strategy (and Ruby `File.expand_path` for Apple). This forces the build scripts to resolve their actual physical location in the monorepo before navigating to the detached engine, surviving Flutter's symlink chaos.

### Step 3: Removing Clutter (The Peer SDK Strategy)
We moved the massive 1GB `google-cloud-sdk` out of the root to a peer directory (`../google-cloud-sdk`) and updated the `infra/gcp_push.sh` and `infra/gcp_bootstrap.sh` scripts to dynamically resolve it. This kept the monorepo pristine while maintaining deployment automation for the Conscia node.

---

## 🏛️ The Birth of RepubLet

With the Sovereign Engine decoupled, it was now trivial to build completely different applications on the exact same infrastructure. 

We introduced **RepubLet**—The Republic of Letters—a scientific publication platform emphasizing the free flow of un-censorable data and explicitly indexing *negative results*.

Because scientific documentation requires intense typography and data visualization (unlike chat), we adopted a **Bi-Platform Architecture**:

1.  **`republet_web` (Desktop)**: A SvelteKit/TypeScript frontend wrapped in Tauri. Because Tauri is built in Rust, we added `republet_desktop` directly to the `exotalk_engine` Cargo workspace. This allows the desktop app to bypass FFI entirely and use `exotalk_core` at native C++ speeds for live calculations!
2.  **`republet_lite` (Mobile notifications)**: A Flutter app that reuses the exact same `rust_builder` FFI bridge as ExoTalk for a lightweight, read-heavy mobile experience.

### The Magic of Shared Identity 🪄
Because both `exotalk_flutter` and `republet_lite`/`desktop` compile against the exact same engine, they automatically share the same Sovereign Vault on the user's hard drive. Your identity, keys, and data history are instantly available across all apps.
