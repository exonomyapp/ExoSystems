# RepubLet Distribution & User Experience Specification

This document defines the distribution strategy for RepubLet, the scientific publication and peer-review platform.

## 1. Philosophical Identity & Independence
RepubLet is the "Knowledge Ledger" of the mesh. It prioritizes data permanence and cryptographic verification of academic authorship, operating as an **entirely independent application**.

**Monetization & Modular Interoperability**: RepubLet empowers authors to commercially offer their content behind **paywalls**, positioning it as a decentralized competitor to platforms like Substack and Medium.com. The revenue-facilitating features of these paywalls modularly accept real fiat money, cryptocurrency, or, optionally, Exonomy vouchers. 

Furthermore, if a RepubLet scientist chooses to initiate an Exocracy project to manage and fund their research, they are stringing together independent modular tools—there is no hard-coupled app-level association between them.

## 2. Platform Distribution Matrix

| Tier | Component | Primary Role |
| :--- | :--- | :--- |
| **Mobile (`_lite`)** | `republet_lite` | Mobile-first Flutter app for real-time reading and push-notifications for peer-review events. |
| **Desktop (`_flutter`)** | `republet_flutter` | Heavy UI Flutter client for academic researchers requiring complex layouts for immutable publishing, deep citation linking, and dataset management. |
| **Indexing Node (`_web`)** | `republet_web` | High-throughput Rust indexing service serving as an academic citation relay and public search gateway for open-science metadata, managed via a Flutter Web dashboard. |

## 3. Related Documents
- [ExoTalk Distribution](exotalk_distribution.md)
- [Conscia Distribution](conscia_distribution.md)
