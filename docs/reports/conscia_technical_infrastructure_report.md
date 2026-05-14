# Report: Conscia Technical Infrastructure Analysis

[ 🏠 Back to Exosystem Root ](../../README.md)

## 1. Philosophical Context: Authorial vs. Collective Needs
The proposed infrastructure extension addresses the tension between the needs of the **individual author** and the desires of the **collective readership community**:

- **Individual Author Needs**: Anchored in the **Personal** context of the sync layer. Authorship is guaranteed by local signing, and the reach of information is governed by **Private** reach-restriction rules.
- **Collective Readership Desires**: Fulfilled by the indexing and velocity layers. Communities require performant discovery, search, and high-speed interaction timelines that the foundational sync layer is not optimized to provide alone.

## 2. Proposed Infrastructure Extensions (Under Consideration)
Based on the analysis in **[conscia-complex.txt](../external/conscia-complex.txt)** and **[slm-rag.txt](../external/slm-rag.txt)**, the following components are being evaluated for the high-performance deployment:

### 2.1 Velocity Layer (ScyllaDB)
- **Role**: High-throughput NoSQL layer for social footprint data.
- **Function**: Accelerates social features (real-time timelines, interaction streams) without storing primary cryptographic truth.

### 2.2 Event Bus & Backpressure (NATS/Redpanda & SQLite/Redb)
- **Role**: Decoupled fan-out and ingestion resilience.
- **Function**: NATS/Redpanda disseminates verified sync events to the indexing, velocity, and vector layers. Local backpressure queues (SQLite or Redb) are used at the ingestion edge to ensure resilience during database maintenance or high-velocity bursts.

### 2.3 Vector Layer & RAG Pipeline (Qdrant)
- **Evaluation**: **Qdrant** is the preferred candidate for its strict **separation of interests** and sys-admin-friendly instance profile.
- **Pipeline Integration**: Asynchronous vectorization runs in parallel via the event bus. It includes **Tombstone Tracking** and soft-deletion flags to ensure that vector chunks are invalidated immediately when a Meadowcap capability is revoked or a credential expires.
- **Credential-Gated Retrieval**: Semantic search results are metadata-filtered by the application using the user's active credential set, ensuring the **Private/Personal** boundary is never crossed.
- **Degradation**: Falls back to pgEdge keyword-only search if the vector store is unavailable.

### 2.4 Observability Stack (Phoenix, Prometheus, Grafana)
- **Role**: System health and performance telemetry.
- **Function**: Provides real-time monitoring of sync throughput, database write latency, event bus lag, and RAG retrieval p99 metrics.

## 3. Optimal Docker Scenario (KIND)
To run the entire test including the proposed database, vector, and observability integrations alongside the settled pgEdge cluster, the most optimal scenario is a **Modular (Multi-Container) Architecture**.

### 3.1 Configuration
- **Isolation**: Separate containers for:
    - `conscia-daemon` (The core sync node)
    - `pgedge-mesh` (3-node multi-master cluster)
    - `scylladb-cluster` (Velocity layer)
    - `qdrant-store` (Vector layer)
    - `nats-bus` (Event fan-out)
    - `observability-stack` (Phoenix, Prometheus, Grafana)
- **Rationale**: This prevents resource contention between the specialized layers (ACID SQL, high-velocity NoSQL, and similarity search) while mirroring a production-grade distributed environment.
- **Orchestration**: Managed via KIND (Kubernetes in Docker) to provide a consistent, failure-isolated testing ground for the entire infrastructure stack.
