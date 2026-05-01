# Walkthrough 37: Screenplays and Delivery Decisions Explainer

This session produced two sets of deliverables: production-ready video screenplays
for all four scenario documents, and a decision-oriented explainer for the three
mesh delivery guarantee design questions.

---

## 1. Screenplays — `docs/scenarios/screenplays/`

Four screenplays created, covering every existing scenario:

| File | Scenario | Runtime |
|---|---|---|
| `README.md` | Production guide: format, recording tools, composition | — |
| `01_p2p_tunnel_sync.md` | Alice & Bob, pure P2P in a tunnel | ~96s |
| `02_conscia_lifeline.md` | Charlie's Mountain Lifeline, Conscia setup & delivery | ~148s |
| `03_federation_governance.md` | Alice & Charlie federate, load share, decommission | ~166s |
| `04_dev_env_federation.md` | Full developer demo, install → federate → offline problem → solution | ~10min |

### Screenplay Format

Each scene specifies:
- **RECORD** — which tool captures it: `asciinema` (terminal), `browser_subagent` (web/RDP).
- **ON SCREEN** — exact terminal output or browser state description.
- **VO** — word-for-word narration script for the AI voice generator.
- **CAPTION** — on-screen text overlay.
- **EST. DURATION** — timing for the video editor.

### Recording Strategy (from README)

- Browser sessions (Conscia dashboard, ExoTalk via RDP) → `browser_subagent` (auto-records WebP video).
- Terminal sessions → `asciinema rec` → converted to video with `agg` or `ffmpeg`.
- Segments concatenated with `ffmpeg -f concat`.
- VO takes are per-scene, fed to the AI voice generator one scene at a time.
- Background soundtrack ducks under VO audio.

---

## 2. `docs/spec/mesh_delivery_decisions.md` — New Explainer

A decision-oriented document written for the project owner (not the implementer).
Covers all three delivery guarantee design problems in full context.

### Structure per Problem

For each of the three questions, the document provides:
1. **What This Is About** — a plain-language explanation with a real-world analogy.
2. **Why It Matters** — the user, operator, and mesh-level stakes.
3. **The Options** — a full menu of realistic alternatives, each with pros, cons, and verdict.
4. **What We Decided** — the current specification, explained.
5. **Open Decision flag** — explicit callout of anything that warrants owner review.

### The Three Problems Covered

**Problem 1 — Retention TTL (How long does a node buffer a message?)**
Options ranged from "forever" to "fixed global" to "per-namespace configurable."
Decision: 72h default, 30d max, signed Tombstone on expiry.
Open question: Is 72h the right default, or should it be 7 days like Signal?

**Problem 2 — Multi-hop relay (Can a message route through intermediate nodes?)**
Options ranged from one-hop-only (simple, brittle) to unlimited hops (loop risk)
to bounded hops (our choice: 5 hops, greedy routing, loop prevention ring buffer).
Open question: Is 5 the right hop limit? Is greedy routing sufficient?

**Problem 3 — Read receipts (What does "delivered" mean?)**
Walks through four distinct delivery states (Sent / Node Received / Client Received / Read)
and explains the privacy trade-off at each layer. Options ranged from no receipts
to full automatic read receipts. Decision: states ① and ② always on, ③ and ④ opt-in
per conversation, Signal-familiar tick UI.
Open question: Global privacy off-switch vs. per-conversation toggle?

### Summary Decision Table

The document closes with a table of the five specific parameter decisions that remain
open for owner confirmation before the v0.8.0 implementation begins.

---

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | ✓ No issues (no Flutter changes this session) |
| `flutter build linux --debug` | ✓ (no Flutter changes this session) |
