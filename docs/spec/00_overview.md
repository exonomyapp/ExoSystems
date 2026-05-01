# Sovereign Exosystem Specification: Overview

This document provides a high-level overview of the Sovereign Exosystem functional specification. It serves as the entry point for understanding the architectural, philosophical, and operational principles that govern the suite.

## 1. The Core Philosophy

The Exosystem is built on the principle of **Sovereign Persistence**. We believe that a user's digital identity, social graph, and content should exist independently of any centralized service provider. 

- **Local-First**: All data is stored and managed locally by default.
- **P2P Mesh**: Synchronization occurs over a peer-to-peer mesh using the Iroh and Willow protocols.
- **Solid Identity**: Cryptographic identifiers (DIDs) are the "Solid Front Door" (Spec 17) through which all interactions flow.

## 2. Shared Infrastructure

At the heart of the Exosystem is `exotalk_core`, a unified Rust engine that handles:
- **Networking**: Encrypted P2P tunnels and mesh discovery.
- **Identity**: Ed25519-based `did:peer` generation and vaulting.
- **Data Sync**: Causally-consistent synchronization of multi-device state.

By sharing this core, every application in the suite—whether it's for chat (**ExoTalk**), economics (**Exonomy**), or governance (**Exocracy**)—benefits from the same security and performance optimizations.

## 3. Specification Roadmap

The documentation in this directory is organized to guide developers and administrators through the layers of the system:

- **Fundamental Architecture**: System design (Spec 01), Identity (Spec 02), and P2P Networking (Spec 03).
- **User Experience Standards**: The "Solid Front Door" (Spec 17) and UI Design Guidelines.
- **Distribution & Acquisition**: The Strategy (Spec 21), Control Panel (Spec 20), and Verification API (Spec 19).
- **Implementation Details**: FFI Bridge (Spec 12) and Build Infrastructure (Spec 13).

## 4. Verification & Quality Assurance

The Exosystem utilizes a **Keystroke-Driven, Visual-Verified (KDVV)** protocol for quality assurance. We prioritize:
1.  **Manual Verification**: High-fidelity visual audits across multiple resolutions.
2.  **Telemetry Auditing**: Programmatic state inquiry via the Spec 19 API.
3.  **Visual Stress-Testing**: Ensuring the "Non-Elastic Frame" maintains integrity under extreme conditions.

> [!IMPORTANT]
> **Programmatic Integration Testing**: Full-suite programmatic integration testing using automated UI drivers (such as the Flutter `integration_test` package) is **indefinitely on hold**. We rely on KDVV for all end-to-end validation.
