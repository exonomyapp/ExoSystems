# Build & Deployment

## Toolchain Requirements
- Rust stable (>=1.70) with `cargo`.
- `flutter` SDK (>=3.19) and `flutter_rust_bridge_codegen`.
- Node.js (>=18) for SvelteKit desktop applications.
- For Android: `cargo-ndk` and Android NDK installed.
- For iOS/macOS: Xcode command-line tools.
- For Tauri Desktop: System dependencies per [Tauri prerequisites](https://tauri.app/start/prerequisites/).

## Build Steps

### Flutter Applications (ExoTalk, Exonomy, RepubLet Lite, Exocracy Lite)
1. Navigate to the app directory (e.g., `cd exotalk_flutter`).
2. Install Dart dependencies: `flutter pub get`.
3. Generate Rust bridge bindings: `flutter_rust_bridge_codegen generate`.
4. Build for your platform: `flutter build <platform>` (e.g., `flutter build linux`, `flutter build apk`).

The `rust_builder` plugin inside each app automatically compiles the correct isolated FFI crate via Cargokit. The `CMakeLists.txt`, `build.gradle`, and `.podspec` files use `REALPATH` resolution to survive Flutter's ephemeral symlink build strategy.

### SvelteKit + Tauri Applications (RepubLet Web, Exocracy Web)
1. Navigate to the app directory (e.g., `cd republet_flutter`).
2. Install Node dependencies: `npm install`.
3. For UI-only development: `npm run dev`.
4. For full native desktop build: `npm run tauri dev`.

The `src-tauri` directory is a symlink to the corresponding Rust backend crate in the root (e.g., `republet_desktop`). Tauri compiles the Rust backend and bundles the SvelteKit frontend into a single native binary.

### Engine Workspace (Validation)
To verify all isolated crates compile harmoniously:
```bash
cd exotalk_engine && cargo check --workspace
```

## CI Recommendations
- Cache the Cargo registry and `target` directory.
- Run `cargo test --all` on each push.
- Verify that generated Dart bridge files are up-to-date per FFI crate.
- Run `npm run build` for SvelteKit apps to validate static asset generation.

## Conscia Deployment Levels

We recognize two primary tiers of Conscia deployment to accommodate both non-technical owners and enterprise administrators. Standardizing on the `conscia` binary, installation relies on robust wizardry and CLI options.

### Level 1: Single Server (Independent Setup)
- **Target:** Non-technical owners and standalone operators.
- **Flow:** An ExoTalk user opens the "Add Node" wizard inside their client. The wizard securely provisions the node using OAuth tokens (GCP, AWS, Oracle) to automatically spin up a single server instance.
- **Uniformity:** The CLI bootstrapping logic (`conscia init`) is architected to mirror the ExoTalk Onboarding Wizard step-for-step, ensuring absolute uniformity whether the node is deployed via terminal or UI.
- **Education:** The wizard includes instructional videos for critical steps.

### Level 2: Advanced Deployment (HA Clusters)
- **Target:** High traffic, mission-critical environments.
- **Topology:** 3-node clusters (1 Master, 2 Slaves) utilizing redundant disks. Slaves provide failover and load-balancing for read/write requests.
- **Infrastructure as Code (IaC):** To provide uniform provisioning across disparate cloud targets (GCP, AWS, Oracle), HA cluster deployments are standardized on **OpenTofu**. This allows users to specify an HA architecture declaratively without worrying about cloud-provider specific APIs, maintaining an independent, open-source toolchain.
- **AI Conscierge:** Advanced deployments support injecting an "AI Key" into the node, allowing an AI agent to become environmentally aware of the Conscia telemetry and autonomously manage resources.

## Laptop-to-Laptop Deployment (Exonomy)
For development between local workstations (e.g., Exocracy to Exonomy), use the local network push:
```bash
# 1. Build locally
cargo build --release -p conscia

# 2. Push and restart via sshpass (assuming local subnet 10.178.118.x)
# 2. Push and restart via sshpass (assuming local subnet 10.178.118.x)
# Note: Use -o PubkeyAuthentication=no to bypass excessive key attempts if locked out.
sshpass -p "." scp -o PubkeyAuthentication=no -o StrictHostKeyChecking=no target/release/conscia exocrat@dev-node.exotalk.tech:~/conscia/conscia
sshpass -p "." ssh -o PubkeyAuthentication=no -o StrictHostKeyChecking=no exocrat@dev-node.exotalk.tech "pkill -9 -f conscia; rm -f ~/conscia/conscia; cd ~/conscia && nohup ./conscia > conscia.log 2>&1 &"

> [!NOTE]
> If a "Database already open" error persists after a restart, ensure the remote storage directory (e.g., `conscia_storage`) is cleared or the process is killed using `fuser` to release the filesystem lock.
```

## GCP Deployment (Conscia Beacon)
Deployment scripts live in `infra/`. The Google Cloud SDK is located as a peer directory (`../google-cloud-sdk`) outside the monorepo to keep the repository clean.
```bash
./infra/gcp_push.sh
```
