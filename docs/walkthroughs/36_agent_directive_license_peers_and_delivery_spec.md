# Walkthrough 36: Agent Directive, License Peers, Delivery Spec & Scenario Expansion

Six items addressed this session across four documents.

---

## 1. `agent.md` — "Replace My Hands, Not My Mind"

Replaced the narrow **"Web UIs over Manual Instructions"** section with a broader
**"Replace My Hands, Not My Mind"** directive. The key change is that automation is
no longer limited to browser-based tasks. The directive now defines a priority stack:

1. **Terminal commands** (`run_command`) — always first; covers local build, install, config, test.
2. **Remote execution via SSH** — for Exonomy or any remote target; includes tunneling.
3. **Browser automation** (`browser_subagent`) — only when there is no CLI/API alternative.
4. **API calls** — `curl` preferred over navigating a web UI for service APIs.

The guiding principle is now explicit: the user provides the decision; the agent
provides the execution.

---

## 2. `docs/license.md` — Peer Comparison Rewrite

Completely rewrote the license analysis to compare ExoTalk against **what the
decentralized ecosystem actually chose**, organized into four tiers:

| Tier | License | Adopted By | ExoTalk Role |
|---|---|---|---|
| 1 | AGPL-3.0 | Mastodon, Matrix Synapse, PeerTube, Lemmy | **Our choice** |
| 2 | GPL-3.0 | Briar, Jami, Signal (original), Meshtastic | Client apps |
| 3 | MIT / Apache 2.0 | Iroh, IPFS, libp2p, Hypercore | Our *dependency* tier |
| 4 | MPL-2.0 | Syncthing | Sync engines |

Signal's upgrade from GPL-3.0 → AGPL-3.0 (in 2019) is highlighted as the definitive
proof point: the network loophole that GPL-3.0 misses is the exact threat model for
Conscia. The new document also includes the full license stack diagram showing
where each layer of the ExoTalk ecosystem sits.

---

## 3. Item 3 — Video Recording Capability

**Yes, with a caveat.** The `browser_subagent` automatically records all browser
sessions as WebP video files to the artifacts directory. For the scenario demo video:

- **Browser steps** (Conscia web dashboard, federation UI, ExoTalk via RDP) can be
  recorded as-is by the browser_subagent.
- **Terminal steps** (cargo run, systemctl, conscia CLI) are not browser-captured.
  For these, `asciinema` or `script` can record terminal sessions as separate artifacts.
- **Composition**: The browser recordings + terminal recordings can be assembled
  offline (e.g., in Kdenlive or FFmpeg) with the AI voice and background soundtrack.

The scenario document is already structured in phases that map cleanly to discrete
recording segments.

---

## 4 & 5. `docs/scenarios/dev_env_federation.md` — Dual-Mode Sections

Sections 1.1 and 1.2 were each expanded into **Mode A** and **Mode B**:

### 1.1 Conscia — Two Modes
- **Mode A (Dev / cargo run)**: Fastest path to the live dashboard; includes SSH
  tunnel command to view Exonomy's dashboard from Exocracy's browser.
- **Mode B (Binary / Apt)**: `cargo build --release` manual path + `apt install`
  automated path; pre-seeded config for server deployments; interactive wizard for
  developer desktops.
- Mode comparison table added.

### 1.2 ExoTalk — Two Modes
- **Mode A (Developer Debug)**: `flutter build linux --debug` + X11 forwarding for
  Exonomy; enables Flutter DevTools inspector.
- **Mode B (End-User / Flatpak)**: `flatpak install` for production; `flutter build
  linux --release` staging bundle as the pre-Flathub path.
- Mode comparison table added.

Section 1.3 verification table updated to reference both Mode A and Mode B surfaces.

---

## 6. `docs/spec/16_mesh_delivery_guarantees.md` — New Spec

Addresses the three open questions from walkthrough 35:

### Retention TTL
- Default: **72 hours**; configurable per namespace (up to 30 days operator cap).
- Expiry generates a signed **Tombstone** that propagates mesh-wide.
- ExoTalk surfaces a `delivery_expired` notification on next client reconnect.

### Multi-Hop Relay
- Maximum **5 hops**, encoded in the gossip envelope `ttl_hops` field.
- Routing: greedy forwarding along any peer with a valid Meadowcap delegation path.
- Loop prevention: sequence number + node ID deduplication ring buffer.
- Failure: `delivery_unreachable` tombstone returned along the relay path.
- Retry: exponential backoff (5m → 15m → 1h → 6h → 24h).

### Read Receipt Semantics
- Four explicit states: **Sent → Node Received → Client Received → Read**.
- UI: single tick → grey double → coloured double → accent double (Signal-familiar).
- **Privacy default**: only states ① and ② (Sent + Node Received) reported to
  sender. States ③ and ④ (Client Received + Read) are **opt-in** per conversation.
- Ack events transit the mesh via the same store-and-forward mechanism as messages.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | ✓ No issues found (carried forward — no Flutter changes this session) |
| `flutter build linux --debug` | ✓ (carried forward — no Flutter changes this session) |
