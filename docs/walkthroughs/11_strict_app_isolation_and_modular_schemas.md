# Walkthrough 11: Strict App Isolation & Modular Schemas

This document records the transition from a "Universal FFI" model to an isolated schema ecosystem to reduce application overhead.

## Universal FFI vs. Strict Isolation

Following the introduction of RepubLet (Walkthrough 10), `exotalk_flutter` and `republet_lite` initially shared a single Flutter FFI translation crate (`rust_lib_exotalk_flutter`). 

This "Universal FFI" approach introduced an application overhead issue. Because the schemas were mixed, ExoTalk included Dart bindings for `ScientificReports`, and RepubLet Lite included bindings for `ChatMessages`. 

## Schema Crates

To decouple `exotalk_core` from data definitions and keep applications lean, the data definition layer was moved into **Modular Schemas**.

Two Rust libraries were added to the Workspace:
1.  **`exotalk_schema`**: Contains models like `DirectMessage`, `Profile`, and `Receipt`.
2.  **`republet_schema`**: Contains models like `ScientificReport`, `Dataset`, and `NegativeResult`.

## Independent Bridges

The monolithic FFI bridge was split into bespoke translators:

1.  **`exotalk_ffi`**
    *   Imports: `exotalk_core` + `exotalk_schema`.
    *   Serves: The `exotalk_flutter` application.
2.  **`republet_ffi`**
    *   Imports: `exotalk_core` + `republet_schema`.
    *   Serves: The `republet_lite` application.

## Toolchain Restructuring

A refactor of the `rust_builder` toolchain was performed for both mobile applications. 

`exotalk_flutter` and `republet_lite` configurations were updated:
*   `flutter_rust_bridge.yaml`
*   `linux/CMakeLists.txt` & `windows/CMakeLists.txt`
*   `android/build.gradle` (updated `libname` passed to cargokit)
*   `ios/*.podspec` & `macos/*.podspec`

Each application now resolves its own specific FFI crate within the `exotalk_engine` workspace, ensuring an isolated build pipeline.

### Conclusion 
The engine architecture is now modular. ExoTalk and RepubLet use the same core P2P networking mesh while maintaining separate domain logic.
