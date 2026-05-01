# 14. Network Traffic Control (Flight Mode)

## 14.1 Concept

The "Traffic Control" system (formerly "Flight Mode") is an application-level network pause feature. In keeping with the spirit of ExoTalk's local-first architecture, it must always remain in the user's power to become entirely local or granularly control their mesh involvement.

Unlike toggling the device's actual Wi-Fi or fully tearing down the Iroh network stack, Traffic Control allows you to independently pause Inbound (Ingress) and Outbound (Egress) mesh activity. The local data replica (the Willow identity vault and chat history) remains fully accessible and functional for reading and drafting regardless of these states.

## 14.2 Behavior

You can configure two independent, persistent toggles:

1. **Inbound Sync (Ingress):** Controls whether your node accepts incoming data and gossip.
2. **Outbound Sync (Egress):** Controls whether your node broadcasts signals, messages, or identity updates.

> [!CAUTION]
> Disabling **Outbound** while keeping **Inbound** enabled allows you to receive "Live" gossip push messages (Lurking mode). However, range-based "Historical Sync" will not function because your node cannot "Dialogue" with peers to tell them what you are missing.

When Inbound Sync is paused:
- The underlying Iroh `accept` loop silently ignores new incoming peer connections.
- The `join_conversation_topic` listener skips processing incoming `GossipEvent::Received` events.

When Outbound Sync is paused:
- The application suppresses outgoing gossip broadcasts in `broadcast_message_hash`. Any locally drafted messages are saved to the local database but are not announced to the mesh.

### 14.3 Visualization (Mesh Metering)
The Home Screen provides a **Mesh Meter** that visualizes these flows in real-time. 
- **Active Flows**: Inbound and Outbound traffic are shown as independent scrolling bar charts.
- **Gated Flow**: If a channel is disabled, its respective lane in the meter will flatline (displayed as a dashed line) to provide visual confirmation of the gated state.
- **Flight Mode**: When both channels are disabled, a "MESH PAUSED" indicator appears.

## 14.4 Implementation Details

The states are tracked via thread-safe static flags (`INGRESS_PAUSED` and `EGRESS_PAUSED`) in the Rust core (`network_internal.rs`). Access is mediated via `RwLock` and exposed to the Flutter UI layer through the `set_ingress_enabled()` and `set_egress_enabled()` FRB bindings. These settings are persisted across reboots via the `IdentityVault`.

```rust
// Mesh logic checks this flag before broadcasting
if is_egress_paused().await {
    tracing::warn!("Egress paused, skipping gossip broadcast");
    return Ok(());
}
```

This model ensures the Iroh QUIC endpoint remains bound and ready, allowing for near-instant resumption of peer-to-peer sync when the user toggles the features back on.
