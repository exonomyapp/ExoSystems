# Spec 28: Management Evolution

Roadmap from tactical diagnostic tools to the industrial-scale Exosystems Management Console (ExoMC).

## 1. The BridgeNode (Tactical)

**Prime Directive**: Monitor routing and availability for temporary live testing over the real internet.

- **Purpose**: A standalone diagnostic tool for the "Testing Season."
- **Scope**: Monitors zrok shares, signaling relays, and local Conscia beacons.
- **Adaptive Nature**: Learns to adapt to temporary technologies (GitHub Pages, dynamic URLs) to achieve the **Direct Handshake**.
- **Mechanism**: Currently uses OS-scraping (`pgrep`, `systemctl`, `journalctl`) for rapid deployment.

## 2. The ExoMC: Exosystems Management Console (Strategic)

**Prime Directive**: Orchestrate intelligent, rule-based relationships between independent nodes and industrial storage tiers.

- **Platform**: Built on **Node-Red** for maximal customization and open standards.
- **Scope**: Industrial-scale management of the Exosystem swarm.
- **Storage Tiering**: Orchestrates industrial storage solutions (as defined in [Spec 27](27_storage_infrastructure_matrix.md)) like SeaweedFS, Garage, and Storj.
- **Sophisticated Awareness**: Nodes possess high-level awareness of each other, managing S3, GCP, and other open-source storage solutions.
- **Distribution**: Published via NPM as a suite of custom Node-Red nodes.

## 3. Transition Path

1.  **Handshake Stabilization**: Finalize the BridgeNode to achieve a deterministic P2P handshake across the internet.
2.  **Telemetry Maturity**: Transition BridgeNode from OS-scraping to the [Telemetry API (Spec 19)](19_verification_telemetry_api.md).
3.  **ExoMC Foundation**: Initialize the Node-Red node suite and begin mapping the "Bridge" logic into reusable Node-Red components.
4.  **Industrial Integration**: Implement the storage orchestration layer for SeaweedFS and Storj.

## 4. Related Specs
- [Spec 20: Distribution Control Panel](20_distribution_control_panel.md)
- [Spec 27: Storage Infrastructure Matrix](27_storage_infrastructure_matrix.md)
- [Spec 19: Verification Telemetry API](19_verification_telemetry_api.md)
