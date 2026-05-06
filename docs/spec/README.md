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
- **[Telemetry Verification (Live)](telemetry_verification.md)**: Real-time results of the programmatic infrastructure stress test.

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

### 🚀 Strategy & Evolution
- **[27. Storage Infrastructure Matrix](27_storage_infrastructure_matrix.md)**: Comparative analysis of S3 and P2P storage solutions.
- **[28. Sovereign Management Evolution](28_sovereign_management_evolution.md)**: Roadmap from **BridgeNode** to the **ExoMC**.
- **[29. KDVV Remote Control Protocol](29_kdvv_remote_control_protocol.md)**: Standards for **Programmatic Humanity** and remote orchestration.

---

### 🤖 Agentic SDLC & Automation (The 3x Series)
- **[30. Agentic SDLC Architecture](30_agentic_sdlc_architecture.md)**: Master blueprint for BMAD, Archon, and BAML integration.
- **[31. BMAD Agile Methodology](31_bmad_agile_methodology.md)**: Definition of the AI Workforce, Personas, and Event-Driven Observers.
- **[32. Archon Workflow Standard](32_archon_workflow_standard.md)**: Strict YAML DAG execution guidelines.
- **[33. BAML Type Safety Protocol](33_baml_type_safety_protocol.md)**: Schema enforcement and prompt reliability layer.
- **[34. GitHub Projects Governance](34_github_projects_governance.md)**: Issue lifecycles, webhooks, and the Flutter Web Cockpit.
- **[35. Observability & Memory Vault](35_observability_and_memory_vault.md)**: Minikube hardware split for Arize Phoenix, Qdrant, and Promptfoo.
- **[36. Exonomy Deployment Standard](36_exonomy_deployment_standard.md)**: Standardized deployment patterns for the Exonomy suite.

---

## 🛠 Usage
These specifications are the "Ground Truth" for the development of ExoTalk and its sister applications. Any significant architectural change must first be reflected in these documents before implementation.
