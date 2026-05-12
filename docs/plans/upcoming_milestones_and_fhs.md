# Comprehensive Implementation Plan: ConSoul & Enterprise FHS Installer

This document outlines the remaining multi-phase implementation roadmap for finalizing **Campaign 1: ConSoul** and deploying the **Enterprise FHS Modular Installer**.

## 1. ConSoul Phase 2 Completion (Data Binding)

**Goal**: Elevate the Federation Administration UI from structural mockups to live data consumers.

### Proposed Changes
#### `conscia_flutter/lib/src/interface/federation/`
- **[MODIFY] `topology_graph.dart`**: Integrate `conscia_provider.dart` to poll `GET /api/federation/topology`. Bind the resulting `FederatedPeer` models to the `flutter_graph_view` data structures.
- **[MODIFY] `proposal_inbox.dart`**: Bind to `GET /api/governance/petitions`. Wire the Approve/Deny buttons to `POST /api/governance/authorize`.
- **[MODIFY] `discovery_qr.dart`**: dynamically fetch the active node's `did:peer` and discovery endpoint URL from the Rust engine, replacing hardcoded strings in the `pretty_qr_code` payload.

---

## 2. ConSoul Phase 3: Service Admin & HITL Governance

**Goal**: Implement the administrative views for configuring local node services and enforcing geographic content locality.

### Proposed Changes
#### `conscia_flutter/lib/src/interface/services/`
- **[NEW] `services_screen.dart`**: A high-density dashboard for toggling Blind Indexing, setting Relay bandwidth limits, and managing Cold Storage pinning for datasets like RepubLet.
- **[NEW] `geographic_context_screen.dart`**: UI for setting local content policies (e.g., "Nairobi circle data stays on African Conscia nodes") and latency-aware routing preferences.

#### `conscia/src/main.rs`
- **[MODIFY] Geographic APIs**: Implement `GET /api/context/geo` and `PATCH /api/context/geo` to serve and update the routing rules database.

---

## 3. ConSoul Phase 4: Cross-Exosystem Service Surface

**Goal**: Expose the configured services to external Exosystem applications (Synesys, Exonomy, ExoTalk).

### Proposed Changes
#### `conscia/src/main.rs`
- **[MODIFY] Relay Configuration**: Implement `POST /api/services/relay/configure` to enforce bandwidth and priority tiers.
- **[MODIFY] Storage Lifecycle**: Implement `POST /api/services/storage/pin`, `DELETE /api/services/storage/unpin`, and `GET /api/services/storage/inventory`.
- **[MODIFY] App Auth Policies**: Implement `POST /api/services/auth/policy` to define exactly which capabilities external apps can request.

---

## 4. Enterprise FHS Modular Installer

**Goal**: Transition from user-space manual deployments to a highly robust, FHS-compliant `.deb` and TUI installation architecture.

### Proposed Changes
#### `exotalk-sys/installer/`
- **[NEW] `tui_installer.rs`**: A `ratatui`-based interactive terminal wizard. This will replace CLI flags, allowing the operator to visually select components (Conscia, Signaling, Zrok, ConSoul) and review the configuration.
- **[NEW] `debian_packaging/`**: Makefiles and `DEBIAN/postinst` scripts that orchestrate building `.deb` packages. The `postinst` script will:
  - Create the non-login `exo-sys` system user.
  - Set permissions (`chown`/`chmod`) on `/opt/exo/`, `/var/lib/exo/`, and `/var/log/exo/`.
  - Execute `systemctl daemon-reload` to register the new systemd orchestrator files.

---

## Verification Plan

### Automated Tests
- Run `cargo test` in `conscia/` to verify new cross-ecosystem and geographic APIs.
- Run `flutter analyze` and `flutter test` in `conscia_flutter/` to ensure Riverpod providers are correctly binding to the FFI layer.
- Run package simulation scripts to verify `.deb` archive integrity and `postinst` execution flows in an ephemeral Docker container.

### Manual Verification
- Launch ConSoul, navigate to Federation Topology, and verify real data appears based on the local dev node's state.
- Compile the TUI installer, run it in a terminal, and confirm the configuration dashboard captures user selections properly.
- Execute a full `.deb` deployment on a fresh test VM, verifying that systemd starts the processes cleanly under `exo-sys`.
