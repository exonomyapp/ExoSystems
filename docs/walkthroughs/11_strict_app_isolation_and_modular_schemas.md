# Walkthrough 11: Strict App Isolation & Modular Schemas

*This document serves as the historical record of our transition from a "Universal FFI" model to a strictly isolated schema Exosystem, guaranteeing zero app bloat.*

## ⚖️ The Universal FFI vs. Strict Isolation

Following the introduction of RepubLet (Walkthrough 10), we initially configured both `exotalk_flutter` and `republet_lite` to share a single Flutter FFI translation crate (`rust_lib_exotalk_flutter`). 

While this "Universal FFI" meant less boilerplate, it introduced a catastrophic conceptual flaw: **App Bloat**.
Because the schemas were mixed, compiling ExoTalk meant shipping Dart bindings for `ScientificReports` (which a chat app will never use), and compiling RepubLet Lite meant shipping bindings for generic `ChatMessages`. 

As RepubLet matures into complex scientific calculation paradigms, this shared overhead would become untenable.

## 🧱 The Solution: Schema Crates

To keep the `exotalk_core` engine pure (unaware of what data it syncs) and to keep the applications lean (only shipping data models they actively use), we decoupled the data definition layer entirely into **Modular Schemas**.

We added two pure Rust libraries to the Workspace:
1.  **`exotalk_schema`**: Exclusively contains models like `DirectMessage`, `Profile`, and `Receipt`.
2.  **`republet_schema`**: Exclusively contains models like `ScientificReport`, `Dataset`, and `NegativeResult`.

## 🌉 Independent Bridges

With the schemas isolated, we then split the monolithic FFI bridge. Instead of one bridge serving all mobile apps, we created bespoke translators:

1.  **`exotalk_ffi`**
    *   Imports: `exotalk_core` + `exotalk_schema`.
    *   Serves: The `exotalk_flutter` application.
2.  **`republet_ffi`**
    *   Imports: `exotalk_core` + `republet_schema`.
    *   Serves: The `republet_lite` application.

## 🪚 Toolchain Surgical Restructuring

We performed a deep surgical refactor of the `rust_builder` toolchain for both mobile apps. 

Inside `exotalk_flutter` and `republet_lite`, we updated their specific:
*   `flutter_rust_bridge.yaml`
*   `linux/CMakeLists.txt` & `windows/CMakeLists.txt`
*   `android/build.gradle` (updating explicitly the `libname` passed to cargokit)
*   `ios/*.podspec` & `macos/*.podspec`

Each app now directly and exclusively resolves its own specific FFI crate within the `exotalk_engine` workspace, ensuring a hermetically sealed build pipeline.

### Conclusion 
The Sovereign Engine is now structurally perfect. ExoTalk and RepubLet compile side-by-side using the same core P2P networking mesh, yet remain strictly ignorant of each other's domain logic.
