# ExoTalk: The Architecture of Autonomy

This document serves as the high-level formal architectural blueprint and vision for ExoTalk, a local-first, P2P social publishing and messaging platform. It synthesizes our technical decisions into a cohesive strategy for a digital node that is "free" (autonomous) and "connectable" (resilient).

*For the philosophical underpinnings of this architecture, please see [The Vision](vision.md).*
*For technical and aesthetic development standards, see the **[Exosystem Standards](exosystem-standards.md)**.*

## Executive Summary of Architectural Decisions

The foundation of this architecture relies on several strict technical choices designed to maximize both user sovereignty and network resilience:

* **Core Protocol:** We are utilizing the **Willow (2025 Spec)**. This provides the mathematical foundation for range-based sync, privacy, and fine-grained permissions.
* **Transport Layer:** The networking is handled by **Iroh (Rust)**. This ensures "Maximal Connectability" through QUIC, UDP hole-punching, and DERP relay fallbacks for robust NAT traversal.
* **Node Topography:** We are adopting a **Unified Reactive Engine** (Rust core interfacing with a Flutter UI). This manages high-performance networking and storage logic, exposed to the UI via a thin FFI layer (`flutter_rust_bridge`) with internal state managed by Riverpod.
  * **Granular Traffic Control:** (Formerly "Flight Mode"). The user retains explicit, independent control over their connection via Inbound and Outbound sync toggles, preserving read/write access to their local Identity Vault while pausing mesh activity.
* **Identity and Authentication:** We rely on **Meadowcap** for capability delegation, supplemented by **ExoAuth (The Universal Passport)** for identity synthesis and OAuth recovery anchors. The `did:peer` remains the sovereign root of trust.
* **Availability:** To solve the offline-peer problem, we introduce **Conscia (The Sovereign Lifeline)**. Always-on nodes act as high-speed mirrors and buffers. These are managed via the **Conscia Management Console (CMC)**.
* **Monetization Interface:** Commercial access to reports and data aggregation is gated via the **Conscire** button, binding the user to a service agreement for advanced analytics.

---

## Product Canvas

This section captures the user-facing features and aesthetic principles that define the ExoTalk experience.

### Core Features

* **P2P Secure Messaging:** Send and receive private, end-to-end encrypted messages directly between peers using the Willow protocol.
* **Decentralized Identity:** Create a unique user identity without a central authority, ensuring privacy and self-sovereignty via `did:peer`.
* **Real-time Sync:** Range-based set reconciliation ensures conversations stay synchronized across all devices in the mesh.
* **Offline First:** Access past conversations and locally stored messages without an active internet connection.
* **Autonomous Groups:** Participate in secure, P2P group chats with cryptographically enforced Meadowcap capabilities.
* **AI Message Draft Assistant:** Utilize a generative AI tool to assist in drafting, rephrasing, or summarizing discussions in context.
* **P2P App Distribution:** Enable direct sharing of the application installer via local connectivity (Bluetooth, Hotspot) to bypass centralized app stores.
* **Rich Media Support:** Integrated camera and microphone support for photos, videos, and voice messages within the P2P fabric.
* **Location & Streaming:** Secure, peer-to-peer sharing of real-time location data and live video streaming.
* **Sovereign Lifeline:** Optional, but encouraged beacon services (**Conscia**) to facilitate offline message delivery and peer discovery without compromising data sovereignty. Managed via the dedicated **CMC** dashboard.

### Style Guidelines

* **Palette:**
    * **Primary:** Deep professional blue (`#2E7ACC`) for trust and connectivity.
    * **Background:** Subtle blue-grey (`#EDF2F6`) for a clean, open canvas.
    * **Accent:** Vibrant indigo (`#514AD6`) for interactive highlights.
* **Typography:** 'Inter' (sans-serif) for modern clarity and readability across all platforms.
* **Iconography:** Minimalist outline icons prioritizing function and clean aesthetics.
* **Motion:** Subtle, smooth transitions for message events and navigation to provide an engaging, fluid user experience.