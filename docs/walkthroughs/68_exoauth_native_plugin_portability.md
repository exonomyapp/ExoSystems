# Walkthrough: exoauth Native Plugin Portability

## Overview

Identity FFI implementation has been finalized by integrating the modularized Rust code with the Flutter native build system.

Previously, the `exoauth` package lacked the native build configuration required to compile the `exoauth_core` Rust crate. This resulted in runtime errors in host applications due to the absence of the `libexoauth_core.so` dynamic library.

By configuring `exoauth` as a Flutter FFI Plugin utilizing `cargokit`, the package now automates the compilation of the native library across Android, iOS, Linux, macOS, and Windows.

## Changes Implemented

### 1. Flutter Plugin Configuration
- Updated `exoauth/pubspec.yaml` to define the package as an `ffiPlugin`. This allows the Flutter toolchain to utilize the native build scripts.

### 2. Native Build Chains
- Integrated the `cargokit` build system.
- Configured native deployment configurations:
  - **Android:** Updated `build.gradle` with namespace `app.exonomy.exoauth`.
  - **iOS & macOS:** Configured `exoauth.podspec`.
  - **Linux & Windows:** Configured `CMakeLists.txt` to reference the `../rust` directory.
- Configured all platforms to compile the `exoauth_core` library.

### 3. Rust Library Configuration
- Added `[lib] crate-type = ["cdylib", "staticlib"]` to `exoauth/rust/Cargo.toml`. This ensures Cargo generates the appropriate library formats for Flutter Rust Bridge.

## Verification

A clean Linux build of `exotalk_flutter` was performed to verify plugin behavior.

```bash
flutter clean && flutter build linux --debug
```

**Result:** The build process successfully utilized `cargokit` to compile and bundle `libexoauth_core.so` into the application's native library directory. `exoauth` is now a standalone identity library.
