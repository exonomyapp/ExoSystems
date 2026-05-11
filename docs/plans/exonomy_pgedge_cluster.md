# Implementation Plan: Exonomy pgEdge Cluster Deployment (Testing Environment)

## 1. Goal
Establish a distributed, high-availability database cluster using **pgEdge** within our local testing environment (**Exonomy**—currently the developer's laptop). This deployment will demonstrate multi-master replication, cross-cluster management, and integration with out-of-mesh communication services.

---

## 2. Background & Strategy
While Conscia relies heavily on Willow/Iroh for decentralized content, certain infrastructure needs are better served by a distributed relational database. pgEdge provides logical, multi-master replication that Conscia can manage as a first-class service.

### 2.1 The Testing Environment
In this phase, **Exonomy** refers specifically to the local laptop environment used for deployment verification. We will utilize **Minikube** to orchestrate the cluster.

### 2.2 Deployment Model
- **Containerized pgEdge**: Deploy pgEdge clusters as Docker containers within Minikube.
- **Federated Clusters**: Configure two distinct pgEdge clusters to both federate (identity/trust) and sync (data replication).
- **Client Isolation**: Launch multiple ExoTalk client containers, pinning specific groups of users to different clusters to demonstrate controlled inter-cluster communication.

---

## 3. Preliminary Requirements
- **Minikube / Docker**: Local orchestration.
- **pgEdge (Spock)**: For logical multi-master replication.
- **Sendgrid API**: For "out-of-mesh" email capabilities.
- **Small Language Models (SLMs)**: Localized AI for diplomatic triage and cross-cluster coordination.

---

## 4. Phased Approach

### Phase 1: Cluster Scaffolding (Minikube)
- Deploy two pgEdge clusters in Minikube.
- Configure internal logical replication using the **Spock** extension.
- Verify cluster health via the pgEdge CLI.

### Phase 2: Conscia Service Integration
- Register pgEdge as a **Conscia Managed Service**.
- Expose pgEdge facilities to application services via **Capabilities**.
- Enable the Conscia UI to manage its own host cluster and peer clusters (where permitted by `did:peer` management tokens).

### Phase 3: Out-of-Mesh Communication & Conscierge
- Configure **Sendgrid** on each cluster for email delivery.
- Deploy a small **SLM** on each cluster to facilitate diplomatic communication.
- Enable the **Conscierge sidecar** to utilize host email services as an alternative "calling home" mechanism when mesh connectivity is unavailable.

### Phase 4: Traffic & Governance Simulation
- Launch ExoTalk clients partitioned across the two clusters.
- Demonstrate administrative control (via Conscia UI) over the flow of communication and data between these user sets.

---

## 5. Verification Plan
- **Multi-Master Sync**: Verify data integrity across pgEdge nodes.
- **Cross-Cluster Management**: Verify the Conscia UI can administer federated clusters.
- **Email Failover**: Simulate mesh isolation and verify the Conscierge can successfully "call home" via Sendgrid.
- **Governance Audit**: Verify that SLM-driven triage correctly filters governance events between clusters.

---

## 6. Open Questions / Design Decisions
- **Spock vs. Platform**: We will initially utilize the **Spock** extension for logical replication within our Docker containers to maintain maximum portability, but may evaluate the full **pgEdge Platform** suite for enterprise management tools.
- **Service Decoration**: How will application services (ExoTalk, Exonomy, etc.) discover and request access to the local pgEdge facilities via the capabilities API?
