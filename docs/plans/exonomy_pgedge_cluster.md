# Implementation Plan: Exonomy pgEdge Cluster Deployment (Testing Environment)

## 1. Goal
Establish a distributed, high-availability database cluster using **pgEdge** within our local testing environment (**Exonomy**—currently the developer's laptop). This deployment will demonstrate multi-master replication, cross-cluster management, and integration with out-of-mesh communication services.

---

## 2. Background & Strategy
While Conscia relies heavily on Willow/Iroh for decentralized content, certain infrastructure needs are better served by a distributed relational database. pgEdge provides logical, multi-master replication that Conscia can manage as a first-class service.

### 2.1 The Testing Environment
In this phase, **Exonomy** refers specifically to the local laptop environment used for deployment verification. We will utilize **KIND (Kubernetes in Docker)** to orchestrate the cluster.

### 2.2 Deployment Model: The 3-Node Mesh
We will deploy a 3-node multi-master cluster with distinct operational roles:
- **`exoNode`**: The external-facing gateway. Handles all data ingress and egress for the Conscia node, serving as the primary interface for remote federation sync.
- **`endoNode`**: The internal community core. Manages the informational needs, indices, and curated reflections specifically for the community this node represents.
- **`nextNode`**: The "High-Ready" standby. Continuously mirrors state and is prepared to assume the role of either `exoNode` or `endoNode` as needed, ensuring zero-downtime failover.

### 2.3 Technology Choice
We utilize the **pgEdge Spock** extension for logical multi-master replication within our containerized testing environment.

---

## 3. Preliminary Requirements
- **KIND / Docker**: Local orchestration.
- **pgEdge (Spock)**: For logical multi-master replication.
- **Sendgrid API**: For "out-of-mesh" email capabilities.
- **Small Language Models (SLMs)**: Localized AI for diplomatic triage and cross-cluster coordination.

---

## 4. Phased Approach

### Phase 1: Cluster Scaffolding (KIND)
- Deploy the 3-node pgEdge cluster (`exoNode`, `endoNode`, `nextNode`) in KIND.
- **Deployment Architecture**: Each node is deployed as an independent Kubernetes Deployment with its own Service, rather than a single StatefulSet. A StatefulSet treats all replicas as identical clones with sequential naming (`pgedge-0`, `pgedge-1`, `pgedge-2`) and cannot assign distinct configurations or behavioral roles to individual pods. Since each node serves a fundamentally different operational purpose, separate Deployments are the only viable approach.
- Configure internal logical replication using the **Spock** extension.
- Verify cluster health and multi-master write-sync via the pgEdge CLI.

### Phase 2: Conscia Service Integration
- **Internal Configuration**: Integrate pgEdge into the Conscia daemon's internal state configuration, allowing Conscia to track pgEdge connection strings, monitor local node health, and locally orchestrate synchronization events across the cluster.
- Expose pgEdge facilities to application services via **Capabilities**.

### Phase 3: Out-of-Mesh Communication & Conscierge
- Configure **Sendgrid** on each cluster for email delivery.
- Deploy a small **SLM** on each cluster to facilitate diplomatic communication.
- Enable the **Conscierge sidecar** to utilize host email services as an alternative "calling home" mechanism when mesh connectivity is unavailable.

### Phase 4: Traffic & Governance Simulation
- Launch ExoTalk clients partitioned across the nodes.
- Demonstrate administrative control (via ConSoul) over the flow of communication and data between these user sets.

---

## 5. Verification Plan
- **Multi-Master Sync**: Verify data integrity across `exoNode`, `endoNode`, and `nextNode`.
- **Failover Transition**: Simulate an `exoNode` failure and verify `nextNode` promotion.
- **Email Failover**: Simulate mesh isolation and verify the Conscierge can successfully "call home" via Sendgrid.
- **Governance Audit**: Verify that SLM-driven triage correctly filters governance events between clusters.

---

## 6. Open Questions / Design Decisions
- **Service Decoration**: How will application services (ExoTalk, Exonomy, etc.) discover and request access to the local pgEdge facilities via the capabilities API?
  - **Proposal**: Application services will query the Conscia daemon's `/api/v1/capabilities/pgedge` endpoint. The daemon will validate the application's Meadowcap capability token and return the internal connection string and localized schema access credentials.
