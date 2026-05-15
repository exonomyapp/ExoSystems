# Specification 22: The Application Triad Architecture

## 1. Overview
The Exosystem comprises several independent applications—ExoTalk (messaging), Exonomy (social voucher exchange), Exocracy (project governance), RepubLet (scientific publishing), and Conscia (Beacon)—each addressing distinct content domains of varying degrees of complexity.

To ensure proper access and knowledge exchange while respecting these varying levels of complexity, all advanced ecosystem applications operate on a **3-Tier "Triad" Architecture**:

1. **`_lite`**: The Mobile-First P2P Client.
2. **`_flutter`**: The Desktop-First Heavy UI Client.
3. **`_web`**: The High-Availability Indexing & Federation Node.

---

## 2. The Ethos of Modular Interoperability
While all applications in the Exosystem share the foundational `exotalk_engine` (providing built-in ExoTalk chat for in-app and cross-app communication), they are engineered as **entirely distinct, independent applications**.

This modularity is the core ethos of the Exosystem:
- They operate independently by default. An Exonomist is not automatically an Exocrat.
- They interact robustly *because they can*, as open systems are meant to do, not because they are part of a rigid, monolithic pipeline.
- Users are encouraged to string these tools together modularly—for instance, a RepubLetist recruiting an Exocrat to manage their research crowdfunding campaign by launching an Exocratic publicity campaign to recruit Exonomists and ask them to mint and contribute their vouchers, which can then be consumed by the research members directly or resold for cash or crypto on Exonomy's open voucher market. Interoperability can be maximized while the applications, themselves, boast zero hard-coupled dependencies on each other's domain logic. A dramatized illustration of this can be further explored for now in the 'Narrative-Driven Implementation' section of the [Project Priorities](./project_priorities.md#3-narrative-driven-implementation) document.

---

## 3. The Application Tiers

### 3.1 The Mobile Client (`_lite`)
- **Underlying Technology**: Flutter (Dart) + Rust FFI (`exotalk_engine`).
- **Target Audience**: Mobile users, field operators, and on-the-go contributors.
- **Scope**: Provides a curated subset of essential features. For Exonomy, this means fast voucher generation and task claiming. For Exocracy, this means quick voting and status updates without the overhead of rendering massive Gantt charts.
- **Custody Model**: Pure peer-to-peer (P2P). Independent custody of all keys and content.

### 3.2 The Desktop Client (`_flutter`)
- **Underlying Technology**: Flutter (Dart) + Rust FFI (`exotalk_engine`).
- **Target Audience**: Content creators, project managers, scientists, and heavy administrators.
- **Scope**: Full access to all complex UI features. This includes wide-screen organizational views, massive dependency trees, and detailed archival management. 
- **Custody Model**: Pure peer-to-peer (P2P). Also P2P. Full node capabilities for local authoring and signing.

### 3.3 The Indexing Node (`_web`)
- **Underlying Technology**: High-throughput Rust API (Axum/Actix) + Flutter Web Administration Dashboard.
- **Target Audience**: Node operators, public searchers, and enterprise hosts.
- **Scope**: Designed to facilitate high availability of fundamentally decentralized content. These nodes provide public or private indexing services so that projects and publications can be freely searched globally (facilitating crowdsourcing and academic discovery). These nodes also offer federation as a higher order of independent P2P design modeling.
- **Custody Model**: **Blind Hosting**. These nodes host encrypted payloads but are entirely blind to the content itself unless explicit capabilities are presented. They only parse and index the **public metadata** that authors explicitly "decorate" their projects/publications with prior to injection.

---

## 4. The Demise of the SvelteKit/Node.js Paradigm
Early iterations of the `_web` indexing layer utilized SvelteKit and Node.js. 
However, anticipating millions of users hitting these indexing nodes simultaneously, the Node.js single-threaded event loop presented a severe bottleneck—specifically during the cryptographic verification of millions of decentralized metadata signatures and content-addressed hashes.

**The Rust + Flutter Web Mandate:**
By replacing the Node.js/Svelte scaffolding with a high-throughput Rust backend, the `_web` tier now shares the exact same memory-safe data schemas (`exotalk_engine`, `republet_schema`) as the P2P clients, eliminating FFI serialization overhead. The administrative UI is built in Flutter Web, allowing massive code reuse from the `_flutter` desktop clients.
