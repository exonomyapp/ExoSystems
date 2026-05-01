# Conscia Nodes (Archival)

## 2.5 Conscia Nodes (Archival)

- **Always‑on Lifelines:** Dedicated headless nodes that act as "Archival Lifelines," ensuring 24/7 message persistence for the swarm at no cost.
- **Reporting Foundation:** These nodes provide the raw data required for the commercialized reporting service (Conscia) when accessed via the **Conscire** agreement.
- **No Authorship Permission:** They can verify, store, and re‑transmit blobs, but lack the cryptographic capabilities to alter history or read end‑to‑end encrypted payloads without explicitly shared capability.
- **Passive Observation:** Conscia operates as a passive participant, utilizing the Willow protocol's range-based reconciliation to ensure comprehensive data collection for future analytics.

## 2.6 High Availability Clustering (Level 2 Deployment)

To support serious enterprise needs, Conscia nodes can be deployed in a **3-Node Cluster** configuration:
- **Topology:** One Master node and two Slave nodes.
- **Redundancy:** Data and identity states are replicated across all nodes. The slave nodes provide immediate failover support if the master experiences an outage.
- **Load Balancing:** Slave nodes actively increase performance by load-balancing inbound queries, telemetry processing, and P2P synchronization requests.

## 2.7 Remote Operationalization

- **Secure Bridging**: Remote Conscia nodes (e.g., Exonomy hardware) are managed via SSH-tunneled sessions to bypass restrictive network topologies.
- **Fluid Verification**: Security handshakes are optimized to enable rapid manual and automated testing of federation whitelisting flows.
