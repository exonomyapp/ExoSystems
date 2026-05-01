# Walkthrough 30: Conscia Identity Architecture & Setup Formalization

This walkthrough documents a major architectural shift defining the deployment, identity, and governance of Conscia nodes across the ExoTalk ecosystem. We formalized the requirement for every Conscia node to anchor itself using a `did:peer`, established robust installation channels, and instituted a rigorous full-build verification standard.

## 1. Architectural Evolution: Conscia Identity
We transitioned Conscia from a "dumb relay pipe" to a governed, stateful actor within the Meadowcap capability system.
- **Node DID Generation:** Every Conscia node is now required to possess an isolated `did:peer` backed by a secure keypair. Nodes integrate into Meadowcap independently, without strictly needing to federate.
- **Uniform Governance:** ExoTalk administrators can now directly delegate Meadowcap capabilities to a node's DID.
- **Key Resolution Tiers:** To mitigate "Key Management Overhead" during hardware failures, we established two support tiers:
  1. **Peer Key Resolution:** Independent Conscia nodes can hold each other's encrypted recovery keys as "mere peers" without obligating themselves to share network state or form a cluster.
  2. **Federated Key Resolution:** High-availability federations that backup keys *and* share full cluster state.

## 2. Deployment Levels & Bootstrapping
We established two tiers of deployment standardized under the `conscia` binary naming convention:
- **Level 1 (Independent Setup):** A wizard-driven deployment inside ExoTalk catering to non-technical users. It utilizes OAuth tokens to instantly spin up standalone servers on cloud providers (GCP, AWS) with built-in instructional videos. The CLI tool (`conscia init`) was mandated to follow the exact same logic as this Wizard for absolute uniformity.
- **Level 2 (HA Clusters):** An advanced deployment for high traffic featuring a 3-node master/slave topology. Slaves provide automatic failover and load-balancing for synchronization requests.
- **AI Conscierge Expansion:** Advanced deployments can optionally provision an "AI Key" to the node, granting an autonomous AI agent environmental awareness of node telemetry for automated resource management.

## 3. Official Installation Instructions
We created a comprehensive `exotalk_engine/conscia/README.md` mapping out native Linux setup instructions. We defined four primary avenues:
- **APT Repository:** `sudo apt install conscia`
- **NPM Package:** `npm install -g conscia`
- **Snap Store:** `sudo snap install conscia`
- **Portable Binary:** Simple `curl` downloads for standalone executable operation.

## 4. Documentation Hygiene & Build Verification
We radically cleaned up the historical and active documentation to ensure rigorous code verification.
- **Walkthrough Purge:** We swept Walkthroughs 03, 06, 16, 17, 18, 19, 22, and 27 to completely eradicate the notion that `flutter analyze` alone guarantees code stability.
- **Full Build Requirement:** All historical references now accurately reflect that a successful full compilation (`flutter build linux --debug` or `cargo build --release`) MUST be paired with static analysis to ensure architectural integrity.

## Specification Updates
These profound changes have been permanently integrated into the core project specifications:
- `docs/spec/02_identity_and_access.md`
- `docs/spec/06_high_availability.md`
- `docs/spec/13_build_deployment.md`
