# Campaign 2: Synesys — The Conscia Browser

## Goal

Mature the ThreeSteps project's Conscia integration into **Synesys** — a read-only, SDUI-driven Conscia browser that allows followers to discover, petition, observe, and consume the services offered by federated Conscia nodes. Synesys is the **consumer** of the services that the Conscia UI (Campaign 1, ExoSystems monorepo) **administers**.

> **Audience**: This plan is written for the ThreeSteps development agent. It provides the architectural direction for building Synesys within the ThreeSteps repository, using the ExoSystems monorepo as the upstream infrastructure provider. This document focuses exclusively on what Synesys must implement. For the authoritative specification of what Conscia provides (services, federation, geographic routing, etc.), refer to the ExoSystems monorepo's [Spec 38: Conscia Federation & Service Architecture](https://github.com/exonomyapp/ExoSystems/blob/master/docs/spec/38_conscia_federation_and_services.md).

---

## Branding & Identity

| Property | Value |
|---|---|
| Product name | **Synesys** |
| Subtitle | The Conscia Browser |
| Monorepo home | ThreeSteps repo (`synesys_flutter/`, `synesys_lite/`, `synesys_web/`) |
| Relationship to Conscia | Read-only client; petitions for access, observes services |
| Relationship to 3S | Synesys is the Conscia-facing component of ThreeSteps, but architecturally independent |

---

## The Synesys Triad

Following the ExoSystems Application Triad Architecture (Spec 22), Synesys operates as its own Triad within the ThreeSteps repo:

| Tier | Directory | Purpose |
|---|---|---|
| Desktop-first | `synesys_flutter/` (Flutter) | Full Conscia browsing, federation topology viewer, deep service introspection |
| Mobile-first | `synesys_lite/` (Flutter) | Lightweight node discovery, petition submission, push notifications for approvals |
| Web | `synesys_web/` (Flutter Web) | Browser-based Conscia browsing for followers without installed apps |

All three tiers consume the same Conscia HTTP API and render their UI dynamically via SDUI blueprints from `GET /api/capabilities`.

---

## Phase 1: Foundation — Sovereign Identity & Node Discovery

### 1.1 Integrate ExoAuth

Add the `exoauth` Flutter plugin from the ExoSystems monorepo to Synesys:

```yaml
# synesys_flutter/pubspec.yaml
dependencies:
  exoauth:
    git:
      url: https://github.com/exonomyapp/ExoSystems.git
      path: exoauth
```

This gives every Synesys instance its own `did:peer` sovereign identity — generated locally on the device using Ed25519 keys, with zero server dependency.

### 1.2 Node Discovery Flow

Implement multi-layer Conscia discovery as defined in ThreeSteps' `docs/spec/discovery.md`:

| Layer | Mechanism | Synesys Action |
|---|---|---|
| A: Local proximity | QR code / BLE / local broadcast | Scan a QR presented by a Conscia operator's Conscia UI; extract the node URL and DID |
| B: Direct introduction | Out-of-band share of `did:peer` + endpoint | Paste a Conscia URL or accept an invite artifact |
| C: Conscia-assisted | TURN/STUN rendezvous | Synesys connects to a known bootstrap Conscia node |
| D: Federated network | Inter-Conscia gossip | Synesys discovers new nodes via a connected Conscia's federation graph |

> **Note**: At Layer A, the Conscia UI (Campaign 1) presents a QR code encoding the node's discovery endpoint and DID. Synesys scans this QR. The QR payload format is defined in Spec 38 §8.

### 1.3 Discovery UI

Build the "Add Conscia Node" screen:
- QR scanner
- URL input field
- "Known Nodes" list (saved favorites)
- Each node shows its `GET /api/discovery` response (see §1.4)

### 1.4 The Discovery Response

The `GET /api/discovery` endpoint returns the node's public identity card. The current response includes `did`, `node_id`, and `version`. The expanded response (as defined in Spec 38 §7) adds:

| Field | Description | Synesys Use |
|---|---|---|
| `did` | Sovereign `did:peer` identity | Verify node authenticity |
| `node_id` | Iroh network identifier | Internal routing |
| `node_name` | Human-readable name | Display in "Known Nodes" list |
| `version` | Conscia daemon version | Compatibility checks |
| `region` | Geographic region (e.g., `eu-central`, `af-east`) | Help followers choose geographically appropriate nodes |
| `locality` | Specific locality (e.g., `berlin`, `nairobi`) | Display local context |
| `connectivity_profile` | Network type (e.g., `datacenter`, `cellular`) | Inform followers about expected reliability |
| `services` | List of active service identifiers | Determine which services this node can provide |
| `federation_active` | Whether node participates in federation | Show federation status badge |
| `federated_peer_count` | Number of active federation peers | Indicate network reach |
| `uptime` | Time since last restart | Inform reliability assessment |
| `operator_contact` | Optional contact URI | Allow petition follow-up |

---

## Phase 2: SDUI-Driven Service Browsing

### 2.1 The SDUI Engine

Synesys does not hardcode its UI for any specific Conscia node. Instead, it calls `GET /api/capabilities` and dynamically renders widgets based on the `sdui_widgets` array in the response.

Each SDUI widget identifier maps to a Flutter widget in Synesys. If the Conscia node does not advertise a widget, Synesys does not render it. If Synesys encounters an unknown widget identifier, it silently ignores it (forward-compatibility).

The authoritative widget registry is maintained in the ExoSystems monorepo at `docs/spec/conscia_sdui_widget_catalog.md`.

### 2.2 Node Profile Awareness

The `GET /api/capabilities` response includes a `node_role` field that describes the node's operational profile (e.g., "Personal Lifeline", "Community Relay", "High-Availability Mesh"). Synesys uses this to adjust the density and depth of information it presents:
- A **Personal Lifeline** node offers fewer services — Synesys renders a simpler, focused interface
- An **HA Mesh** node offers the full service surface — Synesys renders all available widgets

---

## Phase 3: Petition & Capability Workflow

### 3.1 Petition Submission

When a follower wants to access services on a Conscia node, Synesys submits a petition:

```http
POST /api/capabilities/petition
{
  "did": "did:peer:<follower_public_key>",
  "role_requested": "Reader"
}
```

The Conscia node queues this petition. The node operator reviews it in the **Conscia UI** (Campaign 1) and approves or denies it. This is the Human-in-the-Loop checkpoint.

### 3.2 Capability Verification

Synesys periodically polls `POST /api/capabilities/verify` to check if its petition has been approved:

```http
POST /api/capabilities/verify
{ "did": "did:peer:<follower_public_key>" }
```

Once approved, Synesys unlocks additional SDUI widgets based on the granted capability level.

### 3.3 Petition Status UI

- **Pending**: show "Awaiting operator approval" with the node name and timestamp
- **Approved**: show granted role and unlock additional services
- **Denied**: show denial reason (if provided) and allow re-petition

---

## Phase 4: Federation Observation

Synesys provides read-only visibility into the federation topology of Conscia nodes the follower has been granted access to. All management actions remain exclusive to the Conscia UI (Campaign 1).

### 4.1 Federation Topology Viewer (Read-Only)

Synesys consumes `GET /api/federation/topology` and `GET /api/federation/peers` to render:

- **Graph view**: nodes as vertices, federation links as edges
- **Geographic overlay**: region and locality badges on each node
- **Connectivity profiles**: datacenter vs. cellular vs. satellite indicators
- **Latency indicators**: color-coded edges based on inter-node latency measurements
- **Service availability**: which node offers which services (as per the SDUI widget catalog)
- **Node health**: online/degraded/offline status for each federated peer
- **Federated peer count**: total reach of the connected federation network

### 4.2 Geographic Context for Content Decisions

Followers using Synesys can observe:
- **Where their circle's data is replicated** (which geographic regions host copies)
- **Latency to each Conscia node** (to choose the best node for their region)
- **Content locality policies** (e.g., "this circle's data stays in Africa")
- **Connectivity context** (which nodes are on reliable datacenter links vs. intermittent cellular)

This helps followers make informed decisions about which Conscia nodes to petition and helps them understand why certain nodes may be more suitable for their geographic and connectivity context.

---

## Phase 5: Integration with ThreeSteps Core Features — Circles & Forums

ThreeSteps creates circles in the follower app. Conscia nodes create and host forums (indexing surfaces for circles). Synesys bridges these:

- **Forum browsing**: followers discover circles via Conscia-hosted public forums using the `ForumBrowser` SDUI widget
- **Circle metadata**: Synesys renders circle name, type, description, and member count from the metadata index via the `CircleDirectory` widget
- **Join requests**: Synesys submits join requests for circles to the appropriate Conscia node
- **Permission model**: respects the 3-lock visibility model (author → circle owner → forum creator) as defined in ThreeSteps' `docs/spec/indexing.md`

---

## Phase 6: Resilience & Connectivity-Aware Browsing

ThreeSteps serves followers in radically different environments — from urban parish organizers coordinating metropolitan church activities to missionaries performing field work under severe connectivity constraints. Synesys must be valuable to both.

### 6.1 The Urban Follower

A parish organizer in a well-connected metropolitan setting:
- Connects to a nearby **datacenter-hosted HA Mesh** Conscia node
- Browses forums and circles with full search capability
- Uses federation topology to understand which Conscia nodes their parish's circles are replicated to
- Coordinates event logistics and formation activities via Conscia-indexed metadata

### 6.2 The Field Missionary

A missionary working in a region with limited, intermittent, or no connectivity:
- Connects to a **cellular or satellite-linked Community Relay** Conscia node (when available)
- Relies on locally cached discovery data and saved "Known Nodes" for periods of offline operation
- Uses QR-code exchange (Layer A discovery) for local proximity onboarding of new followers
- Submits petitions when connectivity is available; receives approvals asynchronously
- Observes federation topology to understand which nodes might be reachable from their location

### 6.3 Design Implications for Synesys

| Concern | Synesys Must... |
|---|---|
| **Offline tolerance** | Cache the last-known state of all connected Conscia nodes for offline reference |
| **Graceful degradation** | Display stale data with clear "last synced" timestamps rather than blank screens |
| **Connectivity awareness** | Show the follower's current connectivity status and which nodes are reachable |
| **Bandwidth sensitivity** | Request only essential data on constrained connections; defer heavy metadata queries |
| **Local-first petition queueing** | Queue petition submissions locally and send them when connectivity returns |
| **HA transparency** | Show whether a node has failover peers so the follower knows their data persists even if the node goes down |
| **Recovery visibility** | Indicate when a node has recovered from an outage and is back to full health |

---

## Documentation Deliverables (in ThreeSteps repo)

### [NEW] `docs/spec/synesys.md`
Formal specification for Synesys: scope, SDUI model, petition flows, federation observation rules.

### [MODIFY] `docs/tech/tech.md`
Update to reference Synesys as the Conscia-facing component of the ThreeSteps architecture.

### [MODIFY] `docs/spec/discovery.md`
Add Synesys-specific discovery flows, QR scanning, and the expanded discovery response fields.

### [MODIFY] `docs/spec/forums.md`
Cross-reference Synesys as the primary forum browsing surface.

### [MODIFY] `docs/spec/indexing.md`
Document how Synesys consumes metadata indexes from Conscia nodes.

---

## API Contract Dependency (Campaign 1 ↔ Campaign 2)

| Conscia API Endpoint | Campaign 1 (Conscia UI) | Campaign 2 (Synesys) |
|---|---|---|
| `GET /api/discovery` | Displays own identity; presents QR code | Scans QR; discovers and displays nodes |
| `GET /api/capabilities` | Configures SDUI widget availability | Renders SDUI widgets dynamically |
| `POST /api/capabilities/petition` | Reviews petitions (HITL) | Submits petitions |
| `POST /api/capabilities/verify` | N/A (internal) | Checks petition status |
| `GET /api/federation/topology` | Manages federation graph | Observes federation graph (read-only) |
| `GET /api/federation/peers` | Manages peers | Observes peer health, latency, and connectivity |
| `GET /api/context/geo` | Configures geographic routing | Observes geographic distribution and locality |
| `GET /api/index/search` | Manages index policies | Searches public metadata |

---

## Verification Plan

### Automated Tests
- `flutter analyze` on `synesys_flutter/`, `synesys_lite/`, `synesys_web/` — 0 errors
- Unit tests for SDUI widget rendering based on mock `/api/capabilities` responses
- Integration tests for petition submission/verification flow

### Manual Verification
- Connect Synesys to a live Conscia node (e.g., `conscianikolasee.share.zrok.io`)
- Submit a petition and verify it appears in the Conscia UI for review
- Approve the petition in the Conscia UI and verify Synesys unlocks widgets
- Browse federation topology and confirm read-only behavior
- Test offline caching: disconnect, verify cached data displays with "last synced" timestamps
