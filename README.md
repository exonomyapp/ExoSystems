# The Sovereign Exosystem Monorepo

Welcome to the root of the Sovereign Exosystem. This monorepo houses the underlying decentralized engine and the applications designed to defend digital sovereignty in an era of centralized hegemony and IMF-driven digital colonialism.

## 📖 Core Readings
Before diving into code, please read the core philosophical and architectural documents:
*   [The Sovereign Saga (`docs/scenarios/sovereign_saga.md`)](docs/scenarios/sovereign_saga.md) — Our narrative framework.
*   [The Vision Statement (`docs/vision.md`)](docs/vision.md)
*   [The Blueprint (`docs/blueprint.md`)](docs/blueprint.md)

## 🚀 Active Project: ExoTalk
ExoTalk is our flagship self-sovereign messaging application, engineered to operate beyond the reach of **Palantir** algorithms and centralized "kill chains."

### Key Features
- **Sovereign Identity Synthesis**: Local Ed25519 key generation via **ExoAuth (The Universal Passport)**. [Read the Spec](docs/spec/10_identity_vault.md)
- **Instrumentalized Resilience**: Integrated relay support via **Conscia (The Sovereign Lifeline)** for "fail-forward" message delivery. [Read the Spec](docs/spec/conscia_manage.md)
- **Mesh Dynamics**: Real-time visualization of P2P ingress/egress flows, mirroring data across adversarial jurisdictions (e.g., Hangzhou and Frankfurt).
- **Zero-Harvest Architecture**: Local-first storage and peer-to-peer gossiping via Willow & Iroh. [Read the Spec](docs/spec/01_system_architecture.md)

## 🎭 Documentation as Storytelling
We believe that technical documentation should be as engaging as the software itself. Throughout our [Sovereign Saga screenplays](docs/scenarios/exotalk/), we follow protagonists navigating the frontline of digital resistance:

- **Isabella (The Witness)**: An investigative journalist in East Jerusalem documenting truth amidst systematic surveillance.
- **Malik (The Architect)**: A hactivist building solar-powered "Ghost Mesh" relays in Beirut.
- **Zayd (The Orchestrator)**: A businessman in **Hangzhou** federating infrastructure to bypass Western sanctions.

## 🛠 Project Structure

### Core Infrastructure
*   **[exotalk_engine/](exotalk_engine/README.md)**: The Rust-powered P2P heart.
    - **[conscia/](exotalk_engine/conscia/README.md)**: **The Sovereign Lifeline.** Headless beacon & HA relay daemon.
*   **[cmc/](cmc/README.md)**: **Conscia Management Console.** High-density node governance UI.
*   **[infra/](infra/README.md)**: **Sovereign Support Systems.** Signaling relays and diagnostic bridges.

### Shared Modules
*   **[exoauth/](exoauth/README.md)**: **The Universal Passport.** The "Solid Front Door" identity package.

### Applications (The Triad Architecture)
Each application operates on a 3-tier model. See [Specification 22](docs/spec/22_application_triad_architecture.md) for the full architectural rationale.

**ExoTalk** — Sovereign Messaging
*   **[exotalk_flutter/](exotalk_flutter/README.md)**: Desktop messaging client.
*   **[exotalk_web/](exotalk_web/README.md)**: Web-based entry point (Wasm).

**Exonomy** — Social Voucher Exchange
*   **[exonomy_lite/](exonomy_lite/README.md)**: Mobile P2P client.
*   **[exonomy_flutter/](exonomy_flutter/README.md)**: Desktop client.
*   **[exonomy_web/](exonomy_web/README.md)**: Indexing node (Rust + Flutter Web).

**Exocracy** — Decentralized Project Governance
*   **[exocracy_lite/](exocracy_lite/README.md)**: Mobile P2P client.
*   **[exocracy_flutter/](exocracy_flutter/README.md)**: Desktop client.
*   **[exocracy_web/](exocracy_web/README.md)**: Indexing node (Rust + Flutter Web).

**RepubLet** — Scientific Publishing & Archival
*   **[republet_lite/](republet_lite/README.md)**: Mobile P2P client.
*   **[republet_flutter/](republet_flutter/README.md)**: Desktop client.
*   **[republet_web/](republet_web/README.md)**: Indexing node (Rust + Flutter Web).

### Documentation & Specs
*   **[docs/](docs/README.md)**: Centralized system specifications and [ExoTalk Sovereign Scenarios](docs/scenarios/exotalk/).
    - **[Functional Specifications](docs/spec/README.md)**: Master index of all architectural and visual standards.
