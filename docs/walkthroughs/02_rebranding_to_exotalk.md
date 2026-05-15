# Walkthrough 02: Rebranding to ExoTalk

The codebase has been rebranded from "Earthtalk" to "ExoTalk".

## Changes Implemented
- **Directory Renames**:
  - `earthtalk` renamed to `exotalk`.
  - `earthtalk_flutter` renamed to `exotalk_flutter`.
- **Content Replacements**: Updated terminology across text and code files, maintaining casing consistency (e.g., `EarthTalk` to `ExoTalk`).

## Verification
- **Search Verification**: A search for the substring `earthtalk` across the codebase confirmed that all occurrences were replaced.
- **Rust Compiler Verification**: `cargo check` in the `exotalk_flutter/rust` directory verified that package changes were correctly integrated.

## Validation Results
The rebrand operation has been applied across core source files and verified via the Rust compiler.

> [!IMPORTANT]
> To ensure dependency consistency, run `flutter clean` and `flutter pub get` in `exotalk_flutter` to clear cached references to legacy names.
