# Walkthrough 51: Agentic SDLC Architecture

This document summarizes the architectural decisions made to transition the Sovereign Exosystem from manual AI assistance to a fully automated, **Event-Driven Multi-Agent System**.

## 1. What Was Accomplished

We successfully formalized the tooling, personas, and deployment strategy required to govern an autonomous AI workforce. This ensures our agents align with the strict philosophical and technical boundaries of the Exosystem.

### The 3x Specification Series
We authored six new architectural blueprints (`docs/spec/30`-`35`) to act as the "Ground Truth" for this new era:

1.  **[Spec 30: Agentic SDLC Architecture](../spec/30_agentic_sdlc_architecture.md)**: Defines the integration of BMAD (Strategy), Archon (Tactics), and BAML (Reliability).
2.  **[Spec 31: BMAD Agile Methodology](../spec/31_bmad_agile_methodology.md)**: Formally defines our 5-persona agent roster:
    *   *The Sovereign PM*
    *   *The Core Architect*
    *   *The QA Auditor*
    *   *The Flutter/UI Expert* (Enforcing the unified `ExoTheme`)
    *   *The Iroh/Rust Expert*
    *   *The Conscia Strategist*
    *   *The P2P Scientist* (Philosophical Gatekeeper)
    *   *The Documentation Expert* (Hygiene & End-User Docs)
3.  **[Spec 32: Archon Workflow Standard](../spec/32_archon_workflow_standard.md)**: Mandates strict YAML DAGs and KDVV execution limits.
4.  **[Spec 33: BAML Type Safety Protocol](../spec/33_baml_type_safety_protocol.md)**: Enforces schema validation for all LLM interactions.
5.  **[Spec 34: GitHub Projects Governance](../spec/34_github_projects_governance.md)**: Defines "The Cockpit" and the webhook logic required for "On-Demand Brainstorming" and asynchronous SME observation.
6.  **[Spec 35: Observability & Memory Vault](../spec/35_observability_and_memory_vault.md)**: Dictates the critical hardware separation. Exocracy (i7/32GB) hosts the inference engine, while Exonomy hosts Minikube for observability.

### Semantic Refactoring
*   We officially deprecated the term `ConsciaTheme` in favor of the unified **`ExoTheme`**, ensuring the entire Triad (ExoTalk, Exonomy, Exocracy) shares the same aesthetic DNA without overusing the "Sovereign" branding.

---

## 2. Extensive Notes & Architectural Decisions

> [!NOTE]
> **The Hardware Split is Critical:** We identified that running observability databases and memory indexes locally would cripple the primary development machine (Exocracy). By offloading Arize Phoenix, Qdrant, and Promptfoo to a Minikube cluster on Exonomy, we maintain blazing fast local SLM inference speeds while preserving institutional memory.

> [!TIP]
> **Event-Driven AI vs Linear Pipelines:** The biggest leap in this session was abandoning linear AI execution. By using GitHub Webhooks and our custom Cockpit, our SMEs (like the P2P Scientist) act as **Asynchronous Observers**. They can `@mention` each other in GitHub Issues, triggering autonomous sub-threads to debate granular Rust/Iroh implementations before returning a synthesized plan.

> [!IMPORTANT]
> **AI in the Product vs. AI in the Process:** We established a strict demarcation. We will use heavy SLMs (hosted on Exocracy) to power our SDLC tools. Conversely, we are planning to embed *ultra-tiny* models (1.5B parameters) directly into ExoTalk to act as "Intent Brokers" that negotiate with 8B SLMs hosted on remote Conscia nodes, saving mobile battery and bandwidth.
> 
> **Retrospective Correction (Session 56)**: The "Project Cockpit" mentioned in this architecture is a **distinct SDLC governance tool**. It must never be conflated with or implemented within the **Bridge Monitor** product.

---

## 3. What's Next: The Installation Phase

In our next session, we transition from documentation to execution. The following tasks are queued for implementation:

- [ ] **Phase 1: Exonomy Minikube Provisioning**
  - Install Minikube on the Exonomy node.
  - Deploy the **Arize Phoenix** container (for OpenTelemetry tracing).
  - Deploy the **Qdrant** Vector DB container (for LlamaIndex memory).
  - Deploy the **Promptfoo** continuous evaluation server.
- [ ] **Phase 2: Exocracy Local Engine Setup**
  - Install **Ollama** (or `llama.cpp`) to host the local coding SLM.
  - Install the **BAML CLI** (`baml-cli`) and compile our first prompt schema.
  - Install the **Archon** execution engine.
- [ ] **Phase 3: The Cockpit & Webhooks**
  - Scaffold the initial **Flutter Web Dashboard** (The Cockpit).
  - Configure the `gh` CLI credentials and test the GraphQL API connection to GitHub Projects.
  - Setup local listener hooks to intercept GitHub issue events and trigger the local Archon/BMAD python scripts.
