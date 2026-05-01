# License Analysis: ExoTalk & Conscia

This document formalizes the ExoTalk project's licensing decision and explains the
reasoning behind it. The intent is to serve as an evergreen reference for contributors,
legal reviewers, and downstream packagers.

---

## Current Decision: GNU Affero General Public License v3 (AGPL-3.0)

**SPDX identifier:** `AGPL-3.0-only`

Both `exotalk_flutter` and `conscia` are published under the AGPL-3.0. This is a
deliberate and considered choice grounded in how the decentralized, sovereignty-oriented
open-source community has converged on protecting itself. The sections below document
what our peers chose, and why.

---

## How the Decentralized Ecosystem Licenses Itself

Rather than comparing ExoTalk's license choice against options rejected by the P2P
community, this document examines what that community actually *chose* — and what
motivated each decision. ExoTalk sits firmly within this tradition.

---

### Tier 1: AGPL-3.0 — The Federated Services Standard

The AGPL-3.0 has become the **default license for decentralized, federated network
services**. The pattern is consistent: when the product *is* a server that users run
and connect to, AGPL-3.0 is the license that ensures no actor can benefit from the
network without contributing back.

| Project | What it is | License |
|---|---|---|
| **Mastodon** | Federated microblogging (ActivityPub) | AGPL-3.0 |
| **PeerTube** | Federated video hosting | AGPL-3.0 |
| **Pleroma / Akkoma** | Lightweight ActivityPub server | AGPL-3.0 |
| **Pixelfed** | Federated photo sharing | AGPL-3.0 |
| **Matrix Synapse** | Federated chat homeserver | AGPL-3.0 |
| **Conduit** | Rust Matrix homeserver | AGPL-3.0 |
| **Funkwhale** | Federated music platform | AGPL-3.0 |
| **Lemmy** | Federated Reddit alternative | AGPL-3.0 |
| **WriteFreely** | Federated blogging | AGPL-3.0 |

**The shared reasoning:** Every one of these projects is a *network service* whose
value derives from users running federated instances. If a cloud provider could fork
the software, run it as a SaaS, and never disclose their modifications, they would
extract value from the community without contributing back — and they would control
a piece of the supposedly decentralized network. AGPL-3.0's Section 13 makes this
legally untenable.

**ExoTalk's alignment:** Conscia is a Mastodon homeserver for the ExoTalk mesh.
The architectural pattern is identical. Our choice is therefore not novel — it is
the canonical choice of our ecosystem.

---

### Tier 2: GPL-3.0 — End-to-End Encrypted Messaging

A subset of the sovereign communications space chose GPL-3.0 rather than AGPL-3.0.
These are primarily **client applications** or **protocols**, not server-side relay
services, which is why the network loophole of GPL-3.0 is less relevant to them.

| Project | What it is | License |
|---|---|---|
| **Signal (Server)** | Encrypted messaging server | AGPL-3.0 *(upgraded from GPL)* |
| **Briar** | P2P encrypted messaging (Android) | GPL-3.0 |
| **Jami (GNU Ring)** | P2P SIP/video calls | GPL-3.0 |
| **Session** | Lokinet-based private messaging | GPL-3.0 |
| **Meshtastic** | LoRa mesh radio messaging | GPL-3.0 |
| **Tor Browser** | Privacy browser | GPL-3.0 |
| **Tails OS** | Amnesic OS | GPL-3.0 |

**Signal's instructive evolution:** Signal's server was originally GPL-3.0. In 2019,
Signal upgraded the server to AGPL-3.0 precisely because they recognized the network
loophole — someone could fork Signal Server, run proprietary modifications, and never
share the code. Their upgrade is the definitive proof point that for *network services*,
GPL-3.0 alone is insufficient.

**Why ExoTalk chose AGPL over GPL-3.0:** Conscia is a relay service, not a pure P2P
client. The same argument that drove Signal to upgrade applies directly here.

---

### Tier 3: MIT / Apache 2.0 — Protocol Infrastructure and Libraries

A significant portion of the decentralized infrastructure *underneath* applications
uses permissive licenses. The rationale here is **maximum adoption**: protocol
implementations and low-level libraries need to be embeddable everywhere, including
in proprietary products, to become the universal foundation.

| Project | What it is | License |
|---|---|---|
| **Iroh** | P2P networking library *(our core dependency)* | MIT / Apache 2.0 |
| **IPFS / Kubo** | Content-addressed storage | MIT / Apache 2.0 |
| **libp2p** | P2P networking library (Go/Rust) | MIT / Apache 2.0 |
| **Hypercore Protocol** | Append-only log P2P | MIT |
| **Nostr** (clients) | Censorship-resistant notes | MIT |
| **Lightning Network** (LND) | Bitcoin payment routing | MIT |

**The reasoning:** These projects are building *protocol primitives*. If a hospital
wants to build a HIPAA-compliant product on IPFS, the MIT/Apache license does not
block them. The bet is that a ubiquitous protocol creates more net benefit than a
protected one, even if proprietary actors benefit.

**Why ExoTalk does not use MIT/Apache for Conscia:** Iroh (our dependency) correctly
uses MIT/Apache because it is a low-level library. Conscia is *not* a library — it
is a sovereign relay node. Applying library-level permissiveness to a network service
inverts the logic. We *depend* on permissively-licensed protocol libraries; we *publish*
AGPL-3.0 services that use them.

---

### Tier 4: MPL-2.0 — Pragmatic Copyleft for Hybrid Projects

A smaller set of decentralized tools chose the Mozilla Public License, which provides
file-level (rather than project-level) copyleft.

| Project | What it is | License |
|---|---|---|
| **Syncthing** | P2P file synchronization | MPL-2.0 |
| **Veloren** | Open-world multiplayer game | GPL-3.0 / Apache 2.0 (dual) |

**Syncthing's rationale:** Syncthing wants to allow third-party GUIs and integrations
to wrap Syncthing without inheriting the copyleft obligation — only the core Syncthing
files themselves must remain MPL-2.0. This makes sense for a *sync engine library*
used as a building block inside other applications.

**Why MPL-2.0 does not fit ExoTalk:** The file-level boundary is too easily circumvented
for a network service. A proprietary relay could refactor modified logic into new files
and avoid share-alike entirely. ExoTalk's sovereignty guarantee requires project-level
copyleft — not file-level.

---

## Summary: Where ExoTalk Lands

ExoTalk occupies the same space as Mastodon, Matrix, and PeerTube: a **federated
network service** where the server-side codebase must remain open for the decentralized
promise to be meaningful. The AGPL-3.0 is the proven standard for this category.

Our dependency stack (Iroh, Tokio, Axum) sits in Tier 3 — permissively licensed
protocol infrastructure — which is legally sound because AGPL-3.0 code can depend
on MIT/Apache libraries without issue.

```
ExoTalk Ecosystem License Stack:

  exotalk_flutter    ─── AGPL-3.0   (app layer: user-facing client)
  conscia            ─── AGPL-3.0   (service layer: relay node)
  exotalk_core       ─── AGPL-3.0   (engine: FFI bridge)
  ─────────────────────────────────────────────────────
  iroh               ─── MIT/Apache  (P2P primitives — correct tier)
  tokio / axum       ─── MIT         (async runtime — correct tier)
  iroh-gossip        ─── MIT/Apache  (gossip protocol — correct tier)
```

---

## The Dual-Licensing Consideration

Several prominent open-source projects (Qt, MongoDB, GitLab EE) use a dual-licensing
model: AGPL-3.0 for community use, and a commercial license for entities that cannot
comply with the AGPL's disclosure requirements.

**ExoTalk's current stance:** We do not offer a commercial license exception today.
The AGPL-3.0 is unconditional. If an enterprise requires a commercial license, the
appropriate path is to engage ExoSystems Governance directly. This policy may be
revisited as the project matures.

---

## Effect on Specific ExoTalk Workflows

### Distribution Pipeline

| Channel | Requirement |
|---|---|
| `cargo-deb` (Apt) | `.deb` package must include `LICENSE` and source pointer |
| Snap | `snapcraft.yaml` must declare `license: AGPL-3.0` |
| Docker | `Dockerfile` and image labels must reference source repository URL |
| NPM wrapper (`@exotalk/conscia`) | `package.json` `license` field must be `AGPL-3.0`; README must include disclosure |
| Flatpak (ExoTalk Chat) | `*.metainfo.xml` must include `<project_license>AGPL-3.0-only</project_license>` |

### Dependency Compatibility

AGPL-3.0 is compatible with GPL-3.0 (you can link GPL-3.0 libraries into AGPL-3.0
code). It is *incompatible* with Apache 2.0 in the "upstream into Apache" direction,
but Apache 2.0 libraries can be used *within* an AGPL-3.0 project. All current Rust
dependencies (`tokio`, `axum`, `iroh`, etc.) are MIT or Apache 2.0, which is legally
sound.

### Contributor License

Contributors retain copyright to their contributions. By submitting a PR, contributors
agree to license their contribution under the AGPL-3.0 terms of the project. The project
does not require a separate Contributor License Agreement (CLA) at this time.

---

## Quick Reference Matrix

| License | Copyleft Level | Closes Network Loophole | Adopted By (Decentralized) | ExoTalk Role |
|---|---|---|---|---|
| MIT / Apache 2.0 | None | No | Iroh, IPFS, libp2p, Nostr | ✅ Dependency tier |
| GPL-3.0 | Project | No | Briar, Jami, Meshtastic | ⚠️ Client apps only |
| **AGPL-3.0** | **Project + Network** | **Yes** | **Mastodon, Matrix, PeerTube, Signal Server** | **✅ Our choice** |
| MPL-2.0 | File | No | Syncthing | ⚠️ Sync engines only |
