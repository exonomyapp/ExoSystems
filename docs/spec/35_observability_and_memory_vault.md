# 35. Observability & Memory Vault

This specification outlines the offloaded infrastructure required to monitor, debug, and provide persistent memory to our autonomous SDLC agents.

## 1. The Exonomy Minikube Cluster

To preserve the speed and integrity of the Exocracy development workstation, all persistent agent infrastructure is offloaded to the **Exonomy (Conscia)** node.
*   Exonomy utilizes **Minikube** to orchestrate highly-available, containerized infrastructure services.

## 2. Arize Phoenix (Trace Observability)

*   **Purpose**: To provide end-to-end visualization of every LLM interaction, tool call, and Archon DAG execution.
*   **Mechanic**: Archon workflows running on Exocracy explicitly initialize the OpenTelemetry (OTel) SDK. As the local SLM generates tokens, spans are transmitted over the network to the Arize Phoenix container running on Exonomy's Minikube cluster.
*   **Result**: The human orchestrator can open the Phoenix web UI to visually debug agent hallucinations or logic loops.

## 3. Qdrant & LlamaIndex (Institutional Memory)

*   **Purpose**: To prevent "Groundhog Day" regressions by ensuring agents never forget past architectural decisions, PRDs, or `.bmad-output`.
*   **Mechanic**: A **Qdrant** Vector DB container runs on Minikube. A lightweight **LlamaIndex** service continuously ingests changes to the `/docs` directory and completed GitHub Issues.
*   **Result**: When the *P2P Scientist* or *Core Architect* begins a task, it first queries the Exonomy Qdrant DB to load relevant historical context into its active prompt, ensuring long-term project continuity.

## 4. Promptfoo (Continuous Evaluation)

*   **Purpose**: To uphold the "Test Before Deliver" standard for LLM prompts.
*   **Mechanic**: Deployed as a web service on Minikube. When a developer or agent commits a change to a BAML prompt schema, a webhook triggers Promptfoo to run hundreds of regression evaluations. Results are surfaced via the Promptfoo UI on Exonomy.
