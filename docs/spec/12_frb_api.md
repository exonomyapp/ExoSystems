# FRB API Reference

## Architecture

The Exosystem uses **Independent FFI Bridges** — each Flutter application has its own isolated Rust crate that exposes only the functions relevant to that specific app. This prevents cross-compilation of foreign data models.

| FFI Crate | Serves | Imports |
|---|---|---|
| `exotalk_ffi` | ExoTalk Flutter | `exotalk_core` + `exotalk_schema` |
| `republet_ffi` | RepubLet Lite Flutter | `exotalk_core` + `republet_schema` |
| `exonomy_ffi` | Exonomy Flutter | `exotalk_core` + `exonomy_schema` |
| `exocracy_ffi` | Exocracy Lite Flutter | `exotalk_core` + `exocracy_schema` |

## ExoTalk FFI — Exposed Rust‑to‑Dart Functions

| Rust function | Dart wrapper | Description |
|---|---|---|
| `start_iroh_node()` | `startIrohNode()` | Initializes the Unified Engine, starts the Tokio runtime, and establishes Iroh connectivity. |
| `get_stats()` | `getStats()` | Returns live node telemetry (**Conscia Stats**), including Node ID and blob counts. |
| `create_conversation(id: String)` | `createConversation(id)` | Generates a new Willow namespace and joins its associated Gossip topic. |
| `join_conversation_topic(ns: [u8;32])` | `joinConversationTopic(ns)` | Subscribes to a specific Gossip channel for real-time announcements. |
| `send_willow_message(convo_id: String, msg: String)` | `sendWillowMessage(convo, msg)` | Encodes, stores, and broadcasts a signed Willow message to the swarm. |
| `broadcast_message_hash(ns: [u8;32], hash: String)` | `broadcastMessageHash(ns, hash)` | Manually triggers a Gossip announcement for a specific blob hash. |

All functions return `Result<T, String>`; errors are automatically converted to Dart exceptions by `flutter_rust_bridge`.

## Code Generation

Each Flutter app generates its own bridge bindings independently:
```bash
# From within the specific Flutter app directory
flutter_rust_bridge_codegen generate
```

The `flutter_rust_bridge.yaml` in each app's root specifies which FFI crate to target (e.g., `rust_root: ../exotalk_engine/exotalk_ffi/`).
