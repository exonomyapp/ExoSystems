# Walkthrough 70: Conscia Component Extraction

## Overview
Conscia has been relocated from `exotalk_engine/conscia/` to the repository root. This establishes Conscia as a service daemon for the ecosystem, consistent with the Triad Architecture.

## Key Accomplishments

### 1. Crate Extraction & Relocation
- **Relocation**: Moved the Rust binary crate from `exotalk_engine/conscia/` to the root `conscia/` directory.
- **Dependency Realignment**: Updated `conscia/Cargo.toml` to reference `exotalk_engine/exotalk_core` at its new relative path.
- **Asset Integration**: Updated `main.rs` to reference the relocated `exotalk_engine/assets/` directory for the web dashboard.
- **Workspace Cleanup**: Removed `conscia` from the `exotalk_engine` workspace to ensure domain isolation.

### 2. Application Scaffolding
- **Project Creation**: Scaffolded three Flutter projects to complete the Conscia application suite:
  - `conscia_flutter/`: Desktop administration client.
  - `conscia_lite/`: Mobile monitoring client.
  - `conscia_web/`: Web dashboard served by the daemon.
- **Validation**: Scaffolds pass `flutter analyze` with zero errors.

### 3. Infrastructure & Deployment
- **Standardized Paths**: Updated `docs/spec/36_exonomy_deployment_standard.md` with the canonical deployment path: `~/deployments/conscia/daemon/conscia`.
- **Systemd Update**: Updated `infra/exotalk-conscia.service` with new `ExecStart` and `WorkingDirectory` values.
- **Tooling Update**: Updated OpenTofu configurations in `infra/opentofu/variables.tf` to reflect relocated build paths.

### 4. Documentation Update
- **Spec 22**: Defined Conscia as an Independent Application.
- **Ops Guide**: Updated references in `docs/conscia_ops_guide.md`.
- **Agent Documentation**: Audited `agent.md` for path consistency.

## Verification Results
- **Binary Build**: `cargo build --release --bin conscia` verified.
- **Crate Check**: `cargo check` in `conscia/` verified.
- **Workspace Integrity**: `cargo check -p exotalk_core` verified.
- **App Analysis**: `flutter analyze` verified for `exotalk_flutter`.

## Educational Context: Component Decoupling
By extracting Conscia, the service daemon is decoupled from the ExoTalk application. This ensures the daemon remains a stable utility that serves all ecosystem applications independently of application-specific logic changes.
