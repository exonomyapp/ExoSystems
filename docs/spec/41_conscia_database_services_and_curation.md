# Spec 41: Conscia Database Services and Curation

## 1. Introduction
Conscia nodes primarily utilize **Willow/Iroh** for decentralized, p2p data synchronization. To expand the node's capabilities for complex indexing, community reporting, and AI-driven interfaces, a persistent **Database Service** layer is required. This layer supports diverse deployment models (**AOTA**) and serves as a curated reflection of the node's decentralized data state.

## 2. The Curation Pipeline: Willow to SQL
Content does not flow into the database service automatically. It undergoes a "Curation Pipeline" governed by user consent and node policy.

### 2.1 Consent and Access Models
Database persistence is governed by tokens that define how information is curated:
- **Public/Educational**: Shared for the benefit of community summaries, public indexing, and educational feedback loops.
- **Private/Encrypted**: Remains in Willow; never enters the relational database service.
- **Premium/Authorized**: Persisted in the database but gated by Meadowcap capability tokens (e.g., paywalls or organizational roles).

### 2.2 The Curator Worker
A background worker in the Conscia daemon monitors local Willow storage and, based on the defined models, digests content into the relational database. This enables:
- High-performance full-text search across the curated collection.
- Tabulated reporting and metrics for community governance.
- Enhanced context for the node's onboard **Small Language Model (SLM)**.

## 3. Economic Models (Pay and Play)
Conscia supports flexible economic sustainability models enabled by its database services.

### 3.1 Community Participation (Free)
Users who agree to share their data for public curation (the "Play" aspect) can be granted access to the node's educational services without monetary cost.

### 3.2 Private and Premium Services (Pay)
Users requiring private persistence, advanced data processing, or access to restricted organizational data can utilize premium tiers. Access to these database-driven features is issued upon verification of payment or organizational credentials.

## 4. Deployment Flexibility (AOTA)
The database service architecture is designed for **All Of The Above (AOTA)** deployment scenarios:
- **Local/Testing (Exonomy)**: Single-instance PostgreSQL or small pgEdge cluster on a developer's machine.
- **Enterprise**: Multi-master SQL clusters (HA/FT) deployed in private data centers.
- **Cloud/Global**: Federated clusters deployed on cloud platforms (e.g., GCP), enabling global persistence for distributed organizations.

## 5. Conscia Chat (SLM & Database Integration)
With a comprehensive API and a persistent database layer, Conscia can provide a sophisticated human-to-node interface. The onboard SLM utilizes curated database indices to provide natural language interactions with the node's history and metrics, accessible via the **ExoTalk** client.

---
**"Database services are the bridge between raw synchronization and actionable wisdom."**
