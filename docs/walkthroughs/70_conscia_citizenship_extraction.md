# Walkthrough 70: Conscia Citizenship Extraction

## Overview
We have successfully promoted **Conscia** from a nested sub-component (`exotalk_engine/conscia/`) to a first-class, top-level citizen of the sovereign monorepo. This move formally establishes Conscia as the **Sovereign Beacon** for the entire ecosystem (ExoTalk, Exonomy, Exocracy, RepubLet), consistent with the Triad Architecture.

## Key Accomplishments

### 1. Crate Extraction & Promotion
- **Relocation**: Moved the Rust binary crate from `exotalk_engine/conscia/` to root `conscia/`.
- **Dependency Realignment**: Updated `conscia/Cargo.toml` to point to the correct relative path for `exotalk_engine/exotalk_core`.
- **Asset Integration**: Fixed `main.rs` to point to the relocated `exotalk_engine/assets/` folder for the embedded web dashboard.
- **Workspace Cleanup**: Removed `conscia` from the `exotalk_engine` workspace members to ensure strict domain isolation.

### 2. Triad Scaffolding
- **Parity Establishment**: Scaffolded three new Flutter projects to complete the Conscia Triad:
  - `conscia_flutter/`: Desktop-first heavy administration client.
  - `conscia_lite/`: Mobile-first on-the-go monitoring client.
  - `conscia_web/`: Elevated web dashboard served by the daemon.
- **Validation**: All three scaffolds pass `flutter analyze` with 0 errors.

### 3. Infrastructure & Deployment
- **Standardized Paths**: Updated `docs/spec/36_exonomy_deployment_standard.md` to reflect the new canonical deployment path: `~/deployments/conscia/daemon/conscia`.
- **Systemd Update**: Patched `infra/exotalk-conscia.service` to use the new `ExecStart` and `WorkingDirectory` paths.
- **Terraform Readiness**: Updated `infra/opentofu/variables.tf` to point to the new build and deployment locations.

### 4. Documentation Overhaul
- **Spec 22**: Added Conscia as a first-class "Independent Application" alongside Exonomy and Exocracy.
- **Ops Guide**: Fixed stale README references in `docs/conscia_ops_guide.md`.
- **Agent Bible**: Audited `agent.md` to ensure no legacy path references remained.

## Verification Results
- **Binary Build**: `cargo build --release --bin conscia` successful.
- **Crate Check**: `cargo check` in `conscia/` passing cleanly.
- **Workspace Integrity**: `cargo check -p exotalk_core` passing. (Note: Pre-existing FRB versioning issues found in `republet_ffi` identified but verified unrelated to extraction).
- **App Analysis**: `flutter analyze` on `exotalk_flutter` passing with 0 errors.

## 🧠 Educational Context: The "Beacon" Promotion
By extracting Conscia, we have decoupled the "Beacon" (the entry point for the entire mesh) from the "Chat App" (ExoTalk). This ensures that even if ExoTalk logic changes or is swapped, the sovereign beacon remains a stable, lightweight utility that serves all applications equally. Conscia is no longer a "sub-feature"; it is the foundation.
