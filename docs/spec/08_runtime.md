# Async Runtime and Tokio

## Runtime & Concurrency Layer

- **Tokio runtime**: The daemon spawns a dedicated Tokio multi‑threaded runtime on initialization (`init_node()`). This runtime hosts all asynchronous I/O, including the Iroh networking stack and background tasks such as the Publisher‑Led Aggregation worker.
- **Background thread**: A single Tokio thread pool is created so that the Rust daemon never blocks the Flutter UI thread.
- **Graceful shutdown**: `shutdown_node()` signals the runtime to stop accepting new work, flushes pending I/O, and then drops the Tokio runtime. The Flutter side should call the generated `dispose()` function from the FRB bindings when the app exits.
- **Thread‑safety guarantees**: Core structs (`IdentityVault`, `ACTIVE_IDENTITY`, network endpoint) are wrapped in `Arc<RwLock<…>>` and are `Send + Sync`. This ensures safe access from both the runtime and any FRB‑exposed callbacks.
