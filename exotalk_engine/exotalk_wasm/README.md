# ExoTalk Wasm Engine

The WebAssembly (Wasm) core for the browser-based session. This module allows the ExoTalk engine to run securely inside the browser, enabling P2P communication without requiring the user to install a native application.

## Core Concepts

- **Session**: A local-first identity instantiation that manages its own keys and WebRTC connections.
- **Wasm Bindings**: High-performance Rust logic exposed to Javascript via `wasm-bindgen`.
- **WebRTC Handshake**: Peer discovery and connection negotiation using the Signaling Relay.

## Building

To compile the Rust source into a Wasm package for the web:

```bash
# Requires wasm-pack
wasm-pack build --target web --out-dir ../../exotalk_web/pkg
```

## Structure

- `src/lib.rs`: The main entry point for the Wasm bindings.
- `Cargo.toml`: Defines dependencies including `web-sys` for browser API access.

---
*For the frontend implementation that utilizes this engine, see [exotalk_web/](../../exotalk_web/README.md).*
