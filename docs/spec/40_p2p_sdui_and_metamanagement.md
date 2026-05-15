# Specification 40: P2P SDUI & Meta-Management

## 1. Overview
The "Process IS The Product" mandate requires an architecture that is as dynamic as the communities it serves. Traditional app updates are too slow and centralized for an independent mesh. **Specification 40** establishes the **Meta-Management** layer—a paradigm where global application behavior, UI layouts, and functional constraints are managed via **Server-Driven UI (SDUI)** blueprints distributed over P2P gossip.

This allows the operator to instantly update the UX of the entire user population without a physical application upgrade.

---

## 2. The Meta-Management Dashboard

The **ConSoul** interface (**[Campaign 1](../plans/upcoming_milestones_and_fhs.md)**) serves as the "Metamanager Dashboard." From this interface, the operator can author and broadcast UI blueprints that all client applications (**[Triad Tier 1 & 2](./22_application_triad_architecture.md)**) consume.

### 2.1 Managed Domain Logic
The operator can dynamically inject and update:
- **Payment Options**: Adding/removing gateways or crypto-vouchers.
- **Voucher Categories**: Updating the "Exonomy Market" taxonomy.
- **RepubLet Report Types**: Defining new scientific or project reporting templates.
- **Form Schemas**: Modifying fields for petitions, claims, or project registration.
- **Feature Toggles**: Enabling/disabling experimental features for specific cohorts.

---

## 3. Targeting & Segmentation (Criteria-Based Updates)

Updates are not necessarily global. Blueprints can include **Targeting Criteria**, allowing for precision UX management.

### 3.1 Targeting Vectors
| Vector | Description |
|---|---|
| **Geotagging** | Update UI based on the user's `region` or `locality` (e.g., "Nairobi-specific voucher types"). |
| **Forum Membership** | Push specific widgets or report types to members of a particular Conscia-hosted Forum. |
| **Capability/Role** | Change the UI density and available actions based on the user's Meadowcap permission level. |
| **Connectivity Profile** | Target simplified "Lite" blueprints to users on high-latency satellite or cellular links. |
| **App Identity** | Distinguish between Synesys, ExoTalk, Exonomy, and RepubLet clients. |

---

## 4. P2P Distribution: The Willow Angle

Blueprints are not "downloaded" from a central server. They are propagated through the mesh using **Willow's range-based set reconciliation**.

1. **Injection**: The operator saves a new blueprint via the ConSoul interface.
2. **Signature**: The Conscia node signs the blueprint with its `did:peer`.
3. **Gossip**: The blueprint is broadcast over the `exo.mesh.blueprint` gossip topic.
4. **Reconciliation**: Client nodes (ExoTalk, Synesys, etc.) discover the new blueprint during their routine sync dialogue with Conscia nodes.
5. **Hot-Swap**: The client application detects the version change in the blueprint and hot-swaps the UI components without a restart.

---

## 5. The SDUI Catch-22 Resolution

A common challenge in Server-Driven UI is the "Catch-22" of needing an interface to authenticate in order to download the blueprints that build the interface. 
The Exosystem resolves this through ConSoul's `BlueprintProvider`. The UI is built using a Progressive Disclosure Architecture:
1. **Initial State**: ConSoul bootstraps with a fallback/root payload showing only basic diagnostic telemetry.
2. **Local Resolution**: It natively reads the local Willow Data Store for gossiped blueprints rather than hitting an external authentication server.
3. **Dynamic Reveal**: As Meadowcap grants the `did:peer` more capabilities, the `BlueprintProvider` seamlessly injects new navigation routes (like the Federation Administration tab) into the interface without requiring an application restart (**[Campaign 1](../plans/upcoming_milestones_and_fhs.md)**).

---

## 6. The ConsoulCapability Enum

To bridge the cryptographic reality of Meadowcap with the user-facing ConSoul dashboard, we define the `ConsoulCapability` enum. This represents the top-level UI containers authorized by the underlying P2P permissions:

- **`operationalPulse`**: Read-only diagnostic telemetry. Safe to expose as the fallback state before full cryptographic authority is established.
- **`authorityMatrix`**: Grants access to cryptographic node orchestration and service legislation controls.
- **`independentGovernance`**: Grants access to Meadowcap capability management and mesh membership governance.
- **`federationAdministration`**: Grants access to the Meta-Management dashboard (P2P Mesh Topology, HITL capability proposals, and Proximity Discovery).
- **`serviceAdministration`**: Grants access to the administration of active Conscia service decorations (Relay, Blind Indexing, Storage).
- **`geographicContext`**: Grants access to the management of content locality and replication affinity policies.

---

## 7. Architectural Efficacy

By moving domain logic (like categories and payment methods) into SDUI blueprints, we eliminate the need to push new binaries through app stores for routine operational changes. This preserves the **Offline-First** and **independent** nature of the stack, ensuring that once a blueprint is synced, it is available regardless of network state.

### 7.2 The Blueprint Data Model
The Exosystem data model is expanded to include dedicated **Blueprint Content Types**. These are specialized Willow entries that host signed UI blueprints and functional metadata. The Conscia node treats these as high-priority sync items during mesh reconciliation.

---

## 8. Security & Trust
- **Signed Blueprints**: Clients only accept blueprints signed by a trusted Conscia DID.
- **Capability Scoping**: Blueprints cannot bypass Meadowcap-enforced permissions.
- **Federated Governance**: Access to modify or publish blueprints is governed by mutual management permissions between clusters.

---

## 9. Related Documents
- [Spec 38: Conscia Federation & Service Architecture](./38_conscia_federation_and_services.md)
- [Spec 39: Documentation Publishing Pipeline](./39_documentation_publishing_pipeline.md)
- [Conscia SDUI Widget Catalog](./conscia_sdui_widget_catalog.md)
