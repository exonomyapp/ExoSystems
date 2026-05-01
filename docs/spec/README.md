# Exosystem Functional Specifications

This directory contains the formal specifications for the Sovereign Exosystem. These documents define the architectural, operational, and visual standards for all applications in the suite.

## 🧭 Navigation Map

### [00. Overview](00_overview.md)
The starting point: philosophy, shared infrastructure, and documentation roadmap.

---

### 🏗️ Core Architecture
- **[01. System Architecture](01_system_architecture.md)**: High-level component map and engine integration.
- **[02. Identity & Access](02_identity_and_access.md)**: Cryptographic foundations of `did:peer` and vaulting.
- **[03. P2P Networking](03_peer_to_peer_networking.md)**: Mesh topology and discovery logic.
- **[12. FRB API](12_frb_api.md)**: Technical spec for the Flutter-Rust Bridge (FFI) layer.

---

### 🎨 User Experience & Interface
- **[17. Solid Front Door Standard](17_solid_front_door_standard.md)**: The "Non-Elastic Frame" protocol for structural UI stability.
- **[07. UI Functionality](07_ui_functionality.md)**: Component-level specifications and interactive behaviors.
- **[UI Design Guidelines](ui_design_guidelines.md)**: Visual aesthetics, typography, and color tokens.

---

### 📦 Distribution & Acquisition (Production Suite)
- **[20. Distribution Control Panel](20_distribution_control_panel.md)**: **Master Hub** for App IDs, Docker naming, and acquisition syntax.
- **[21. Distribution Strategy](21_distribution_and_acquisition_strategy.md)**: (Coming Soon) Unified strategy for Flatpak, Docker, and App Stores.
- **[19. Verification Telemetry API](19_verification_telemetry_api.md)**: Port 11434 sidecar for automated health auditing.

---

### ⚙️ Implementation & DevOps
- **[13. Build Infrastructure](13_build_deployment.md)**: Toolchains, CI/CD, and internal developer deployment.
- **[11. Meadowcap Capabilities](11_meadowcap_capabilities.md)**: Advanced capability-based security model.
- **[16. Mesh Delivery Guarantees](16_mesh_delivery_guarantees.md)**: Reliability and ordering protocols.

---

### 🗄️ Specialized & Legacy
- **[Legacy Archive](legacy/)**: Preserved individual app distribution specs.
- **[Conscia Management](conscia_manage.md)**: Specific operations for the Conscia node.
- **[Mesh Delivery Decisions](mesh_delivery_decisions.md)**: Rationale behind low-level networking choices.

---

## 🛠 Usage
These specifications are the "Ground Truth" for the development of ExoTalk and its sister applications. Any significant architectural change must first be reflected in these documents before implementation.
