# 30. Agentic SDLC Architecture

This specification outlines the foundational architecture of the Exosystem's Agent-Driven Software Development Life Cycle (SDLC). It defines the tools, hardware deployment strategy, and the philosophical boundaries of AI-assisted engineering.

## 1. The Stack: Strategy, Tactics, and Reliability

To maintain the high-density complexity of the Exosystem while scaling rapidly, we employ a 3-tier agentic stack:

*   **Strategy Layer (BMAD v6.2+)**: **B**reakthrough **M**ethod for **A**gile AI-**D**riven Development. This layer simulates a full human engineering team. It handles project scoping, architectural validation, and orchestrates the creation of Product Requirements Documents (PRDs).
*   **Tactics Layer (Archon)**: The execution engine. Archon translates the strategic goals of BMAD into deterministic, YAML-defined Directed Acyclic Graphs (DAGs). It automates raw code writing, bash scripting, and CI/CD validation.
*   **Reliability Layer (BAML)**: **B**oundary**ML**. This acts as the type-safety net. All LLM prompts and JSON outputs requested by Archon or BMAD are strictly schema-validated via BAML, eliminating hallucinated keys and ensuring robust programatic interaction.

## 2. Hardware Segregation & Inference

We explicitly separate the execution of Agentic tasks from the persistence of their telemetry and memory.

### 2.1 Exocracy Workstation
*   **Role**: Primary compilation environment, IDE host, and active agent execution host.
*   **Hardware**: High-performance CPU (i7), 32GB RAM.
*   **Responsibilities**: 
    *   Hosts the heavy Small Language Model (SLM) inference engine (e.g., Ollama running a local 8B+ coding model).
    *   Executes Archon DAGs and modifies the local source code filesystem.
    *   Fires OpenTelemetry (OTel) signals over the network to the observability layer.

### 2.2 Exonomy (The Infrastructure Node / Conscia Host)
*   **Role**: The highly-available "Lifeline" for the SDLC stack.
*   **Hardware**: Lower tier CPU, 12GB RAM, highly available.
*   **Responsibilities**:
    *   Hosts **Minikube**, providing self-healing container orchestration.
    *   Runs **Arize Phoenix** for capturing and visualizing OpenTelemetry traces.
    *   Hosts **Qdrant (Vector DB)** and **LlamaIndex** pipelines to serve as the persistent, always-on institutional memory for agents.
    *   Runs the **Promptfoo** continuous evaluation service to automatically test BAML regressions on commit.


## 3. The Agentic SDLC Cockpit

> [!CAUTION]
> **PRODUCT BOUNDARY ENFORCEMENT**: The Agentic SDLC Cockpit is a **strictly internal development tool**. It is entirely distinct from the **Bridge Monitor** (the node operator's product). Do NOT conflate these two dashboards. The Cockpit monitors our *coding process*; the Bridge Monitor monitors the *mesh bridge*.

GitHub Projects serves as the canonical state-store for tasks. However, to facilitate the **Event-Driven Multi-Agent System** (see [Spec 31](31_bmad_agile_methodology.md)), a custom **Flutter Web Dashboard** (The Agentic SDLC Cockpit) acts as the governance bridge between our agents and the human orchestrator.

The Cockpit polls GitHub's GraphQL API and presents a specialized AI-Governance view, allowing the human orchestrator to instantly see which agents are blocked on approval, view trace failures from Arize Phoenix, and monitor architectural drift in our internal agentic workflows.
