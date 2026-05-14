# Exosystem Glossary

[ 🏠 Back to Exosystem Root ](../README.md)

> [!NOTE]
> This glossary tracks the "Truth throughout the monorepo's spacetime continuum." It is a living record of terminology definitions, their chronological history, and their contextual framing within the monorepo.

---

## Terminology Matrix

### `Conscia`
- **Definition**: The authoritative beacon node of the monorepo. A headless Rust daemon that operates as an autonomous participant in the P2P mesh, providing service-layer capabilities (Relay, Indexing, Discovery, Federation) while maintaining content-agnostic data synchronization.
- **History**:
    1.  **[Walkthrough 00](walkthroughs/00_migration_legacy_summary.md)**: Introduced as the core service daemon (initially described as the "Beacon").
    2.  **[Walkthrough 70](walkthroughs/70_conscia_citizenship_extraction.md)**: Formally extracted as a top-level monorepo citizen.
- **Category**: Core / Infrastructure.
- **Function**: P2P state management, API services, and federation.
- **Last Edited**: 2026-05-13 (Walkthrough 78).

### `ConsciaLet` (UNDER DISCUSSION)
- **Definition**: A proposed federation module and interface for managing inter-node relationships.
- **History**:
    1.  **[Spec 38](spec/38_conscia_federation_and_services.md)**: Formulated as the proposed interface for peer relationship management and diplomatic negotiation.
- **Category**: UI / Federation (Proposed).
- **Function**: Peer registration and relationship auditing.
- **Last Edited**: 2026-05-13 (Spec 38 update).

### `ConSoul`
- **Definition**: The administrative console for the Conscia node. A desktop-first Flutter application that provides diagnostics, telemetry, and service management.
- **History**:
    1.  **[Walkthrough 74](walkthroughs/74_consoul_foundation.md)**: Established as the unified administrative gateway.
- **Category**: UI / Management.
- **Function**: Telemetry visualization and service configuration.
- **Last Edited**: 2026-05-13 (Walkthrough 78).

### `exo-sys`
- **Definition**: The canonical Linux system user responsible for executing all headless Exonomy services (Conscia, Zrok) within the FHS-compliant architecture.
- **History**:
    1.  **[Walkthrough 77](walkthroughs/77_fhs_installer_finalization.md)**: Established as the authoritative service user, replacing the legacy `exotalk-sys`.
- **Category**: Infrastructure / Security.
- **Function**: Service ownership and execution.
- **Last Edited**: 2026-05-12 (Spec 36).

### `exotalk-sys` (DEPRECATED)
- **Definition**: The legacy service user name used during the initial prototyping phase of the node deployment.
- **History**:
    1.  Introduced: Early prototyping phase.
    2.  Demise: **[Walkthrough 77](walkthroughs/77_fhs_installer_finalization.md)** (Replaced by `exo-sys`).
- **Category**: Infrastructure / Legacy.
- **Function**: Early service management.

### `Personal`
- **Definition**: The context of publishing. It defines the authorial environment from which the information originates, establishing identity via cryptographic signatures.
- **History**:
    1.  **[Spec 41](spec/41_conscia_database_services_and_curation.md)**: Formally distinguished from "Private" to refine the curation and publishing paradigm.
- **Category**: Architectural.
- **Function**: Authorial anchoring and context.

### `Private`
- **Definition**: The restriction on the reach of publication. It defines which peers are authorized to synchronize or view specific data.
- **History**:
    1.  **[Spec 41](spec/41_conscia_database_services_and_curation.md)**: Formally distinguished from "Personal" to clarify data sovereignty vs. data privacy.
- **Category**: Architectural / Security.
- **Function**: Reach restriction and access control.

### `Willow`
- **Definition**: The foundational data synchronization protocol for the P2P layer. It provides eventually-consistent, cryptographically verifiable data spaces.
- **History**:
    1.  **[Walkthrough 00](walkthroughs/00_migration_legacy_summary.md)**: Introduced as the core engine for decentralized state synchronization.
- **Category**: Core / Protocol.
- **Function**: Data synchronization and provenance.
- **Last Edited**: 2026-05-13 (Walkthrough 75).

---
