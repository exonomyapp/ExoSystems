# Walkthrough 51: Agentic SDLC Architecture

This document summarizes the architectural decisions made to transition the development process to an event-driven multi-agent architecture.

## 1. Accomplishments

Tooling, agent personas, and deployment strategies were formalized to manage development agents within the project's technical boundaries.

### Architectural Specifications
Six architectural blueprints (`docs/spec/30`-`35`) were authored to define the system:

1.  **[Spec 30: Agentic SDLC Architecture](../spec/30_agentic_sdlc_architecture.md)**: Integration of strategy, tactics, and reliability layers.
2.  **[Spec 31: Development Methodology](../spec/31_bmad_agile_methodology.md)**: Defines the agent roster:
    *   Project Management Agent
    *   Architecture Agent
    *   Audit Agent
    *   UI Expert (Enforcing `ExoTheme`)
    *   Rust/Network Expert
    *   Documentation Agent
3.  **[Spec 32: Workflow Standard](../spec/32_archon_workflow_standard.md)**: Mandates DAG-based execution and verification limits.
4.  **[Spec 33: Type Safety Protocol](../spec/33_baml_type_safety_protocol.md)**: Enforces schema validation for model interactions.
5.  **[Spec 34: Project Governance](../spec/34_github_projects_governance.md)**: Defines the management dashboard and webhook logic for asynchronous observation.
6.  **[Spec 35: Observability & State Management](../spec/35_observability_and_memory_vault.md)**: Defines hardware separation. Exocracy hosts the inference engine, while Exonomy hosts the observability cluster.

### Naming Standardization
The term `ConsciaTheme` was deprecated in favor of **`ExoTheme`**, ensuring unified UI standards across the platform (ExoTalk, Exonomy, Exocracy).

---

## 2. Architectural Decisions

> [!NOTE]
> **Hardware Distribution:** Observability databases and memory indexes are hosted on Exonomy via a Minikube cluster. This maintains high-performance local inference on the primary development machine (Exocracy).

> [!TIP]
> **Event-Driven Architecture:** The system utilizes GitHub Webhooks and a management dashboard. Agents act as asynchronous processes, utilizing GitHub Issues to coordinate implementation plans before synthesis.

> [!IMPORTANT]
> **Model Integration:** Local inference engines power SDLC tools. Small-scale models are planned for integration into ExoTalk to act as routing agents for interaction with remote nodes.

> [!IMPORTANT]
> **Project Cockpit Distinction**: The project management dashboard is a development governance tool and is distinct from the **Bridge Monitor** product.

---

**Verification**: Verified via architectural review and specification audit.
