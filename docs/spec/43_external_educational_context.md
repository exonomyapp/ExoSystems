# External Educational Context

This document serves as the canonical source for educational context and developer guidance for files within the monorepo that do not support native commenting (e.g., JSON files, binary assets, or strict configuration formats).

---

## [conscia/npm/package.json](file:///home/exocrat/code/exotalk/conscia/npm/package.json)
**Context**: This `package.json` defines the NPM delivery wrapper for the Conscia Beacon. While the core logic is in Rust (`conscia/src/main.rs`), this wrapper allows the binary to be distributed and installed via standard JavaScript tooling. The `bin` field maps the `conscia` command to a JavaScript entry point that invokes the native binary.

**Mentor Tip**: When updating the version here, ensure it matches the `CARGO_PKG_VERSION` in `conscia/Cargo.toml` to maintain consistency across delivery channels.
