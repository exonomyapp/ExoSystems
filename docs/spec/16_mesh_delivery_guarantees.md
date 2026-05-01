# Spec 16: Mesh Delivery Guarantees

This specification defines the delivery semantics of the ExoTalk gossip mesh as
mediated by Conscia. It addresses three foundational questions that determine the
reliability contract users and operators can depend on.

---

## 1. Gossip Event Retention (TTL Policy)

### Problem Statement

When Exocracy's ExoTalk is offline, its Conscia node buffers incoming gossip events
on its behalf. How long does that buffer live? What happens when it is exhausted?

### Definitions

- **Gossip Event**: A single signed message payload, keyed by its originating
  `did:peer` namespace and a monotonic sequence number.
- **TTL (Time-To-Live)**: The maximum duration a Conscia node will hold an undelivered
  event before discarding it.
- **Tombstone**: A signed deletion record that explicitly marks an event as expired
  or retracted. Unlike silent expiry, a tombstone propagates through the mesh so that
  all nodes can purge consistently.

### Policy

| Parameter | Default | Configurable? |
|---|---|---|
| Default TTL | **72 hours** | Yes — per namespace in `config.toml` |
| Maximum TTL | **30 days** | Yes — operator-level cap |
| Minimum TTL | **1 hour** | No — hard floor to prevent misconfiguration |
| Storage cap | **500 MB** per node | Yes — operator-level cap |
| Eviction order | Oldest first (LRU) | No |

```toml
# Example: conscia config.toml namespace overrides
[retention]
default_ttl_hours = 72
max_ttl_days = 30
storage_cap_mb = 500

[retention.namespaces]
# Per-namespace override: grant longer retention for high-priority team channels
"did:peer:team_channel_namespace" = { ttl_hours = 720 }
```

### Expiry Behaviour

1. When an event's TTL elapses, the node emits a **Tombstone** signed with the node's
   Meadowcap key.
2. The Tombstone propagates to all federated peers so they can also purge the event.
3. The originating ExoTalk client receives a `delivery_expired` notification the next
   time it connects. It may choose to surface this to the user (e.g., "3 messages
   expired before delivery").

### Design Rationale

72 hours is the default because it covers the "weekend offline" scenario (the most
common case for personal Lifeline nodes) while keeping storage requirements bounded.
Operators running HA Community Relay nodes may extend this to 30 days for enterprise
compliance use cases.

---

## 2. Multi-Hop Relay Routing

### Problem Statement

If Exocracy's Conscia node is *also* offline when Exonomy sends a message, can the
event still be delivered? Can the mesh route through intermediate nodes?

### Answer: Yes — with Bounded Hop Limits

A federated Conscia mesh is a directed graph where each node has a set of authorized
peers. Multi-hop routing allows a gossip event to transit through N intermediate nodes
to reach a recipient whose direct Conscia is temporarily unreachable.

### Routing Model

```
Exonomy Conscia  →  (hop 1) Community Relay  →  (hop 2) Exocracy Conscia
```

Each node in the path must hold a valid Meadowcap delegation chain proving it is
authorized to relay traffic for the destination namespace.

| Parameter | Value |
|---|---|
| Maximum hop count | **5** (hard limit, encoded in gossip header) |
| Routing strategy | Greedy — forward to any peer that has a delegation path to the destination |
| Loop prevention | Sequence number + node ID deduplication ring buffer (last 10,000 events) |
| Hop decrement | Each relay decrements a `ttl_hops` field in the gossip envelope |

### Gossip Envelope Header (Extended)

```json
{
  "event_id": "uuid-v4",
  "origin_did": "did:peer:exonomy_user",
  "target_namespace": "did:peer:exocracy_user_namespace",
  "sequence": 42,
  "timestamp_ms": 1745524800000,
  "ttl_hops": 5,
  "relay_path": ["exonomy_node_id", "relay_node_id"],
  "signature": "ed25519_sig"
}
```

### Failure Case

If `ttl_hops` reaches 0 before delivery, the last relay node emits a
`delivery_unreachable` tombstone back along the relay path. The originating ExoTalk
client displays "Could not reach recipient — retrying in N minutes."

### Delivery Retry

If the direct target Conscia comes back online within the original event's TTL, any
intermediate relay node that holds the buffered event will re-attempt direct delivery.
The retry interval follows **exponential backoff**: 5 min → 15 min → 1 hr → 6 hr → 24 hr.

---

## 3. Read Receipt Delivery Semantics

### Problem Statement

When is a message "delivered"? When is it "read"? These are distinct events with
different UX implications. The ExoTalk ecosystem defines three explicit delivery states.

### The Three Delivery States

```
Sent → Node Received → Client Received → Read
 ①         ②                ③             ④
```

| State | Event Name | Trigger | Who Generates It |
|---|---|---|---|
| ① **Sent** | `message_sent` | Originating ExoTalk submits to local Conscia | Originating ExoTalk |
| ② **Node Received** | `delivery_relay_ack` | Destination Conscia accepts and stores the event | Destination Conscia |
| ③ **Client Received** | `delivery_client_ack` | Destination ExoTalk pulls and decrypts the event | Destination ExoTalk |
| ④ **Read** | `delivery_read_ack` | User views the message in the conversation | Destination ExoTalk |

### UX Mapping

| State | ExoTalk UI indicator |
|---|---|
| Sent | Single tick `✓` |
| Node Received | Double tick `✓✓` (grey) |
| Client Received | Double tick `✓✓` (coloured) |
| Read | Double tick `✓✓` (accent colour) |

This is intentionally analogous to Signal and WhatsApp's tick semantics because users
carry that mental model. The distinction is that **Node Received** is a new intermediate
state that only exists because Conscia provides store-and-forward. In a pure P2P session
(no Conscia), states ② and ③ collapse into one.

### Privacy Consideration

**Read receipts are opt-in per conversation.** By default, only states ① and ② are
reported to the sender. States ③ and ④ (`client_received` and `read`) are disabled
by default and must be explicitly enabled by the recipient in their privacy settings.
This mirrors Signal's approach: the sender knows the infrastructure received the
message, but not whether the human has seen it, unless the human chooses to share that.

### Technical Implementation

Each ack event is itself a gossip event published to the conversation namespace,
signed by the acknowledging party (Conscia node for ②, ExoTalk client for ③ and ④).
They transit the same relay path in reverse. This means:

- If the sender is offline when the ack is generated, it will be delivered when the
  sender reconnects — using the same store-and-forward mechanism that delivers messages.
- Ack events have a **fixed TTL of 7 days** (not configurable), after which they
  are silently discarded. Undelivered acks do not block future message delivery.

---

## Implementation Priority

| Feature | Status | Target Release |
|---|---|---|
| Default TTL (72 hr) + storage cap | 📋 Planned | v0.8.0 |
| Per-namespace TTL config | 📋 Planned | v0.8.0 |
| Tombstone propagation | 📋 Planned | v0.8.0 |
| Multi-hop routing (5 hops) | 📋 Planned | v0.9.0 |
| Exponential backoff retry | 📋 Planned | v0.9.0 |
| Node Received ack (state ②) | 📋 Planned | v0.8.0 |
| Client Received + Read ack (states ③ ④) | 📋 Planned | v0.9.0 |
| Privacy toggle for read receipts | 📋 Planned | v0.9.0 |
