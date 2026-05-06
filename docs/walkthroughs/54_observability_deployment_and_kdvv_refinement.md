# Walkthrough 54: Observability Deployment & KDVV Refinement

## Overview
This session finalized the deployment of the Minikube-based observability stack on the **Exonomy** node. It also refined the **Keystroke-Driven, Visual-Verified (KDVV)** protocol to balance educational transparency with operational efficiency.

## 1. Infrastructure Deployment
We successfully deployed the vector memory and observability baseline to the Minikube cluster on Exonomy.

### Deployments (`~/deployments/k8s/observability/`)
- **Qdrant**: Vector database for agentic memory.
    - Image: `qdrant/qdrant:v1.9.0`
    - Status: `Running`
- **Arize Phoenix**: Observability and trace monitoring.
    - Image: `arizephoenix/phoenix:latest`
    - Status: `Running`

### Remediation & Fixes
- **Image Repository Correction**: Fixed the Phoenix image from `arizeai/phoenix` (incorrect) to `arizephoenix/phoenix`.
- **Version Pinning**: Pinned Qdrant to `v1.9.0` to resolve startup panics observed with the `latest` tag in the Minikube environment.
- **Directory Enforcement**: Cleaned up `~/code/exotalk` on Exonomy and migrated manifests to the formal `~/deployments/` path.

## 2. KDVV Protocol Refinement (`agent.md`)
We updated the core agent instructions to better handle high-frequency interactions:
- **Typing Delay**: Standardized `xdotool type --delay 50` for human-readable execution.
- **Background Verification**: Permitted non-visual "pings" for internal state verification (e.g., checking pod status via SSH) to speed up workflows, while keeping modifications and educational steps strictly visual.

## 3. Visual Verification Evidence
The deployment was verified visually in the `AI-EXONOMY` terminal.

![Observability Pods Running](file:///tmp/scrot.png)

---

## ⏭️ What's Next: The 40% CPU Floor Investigation

1.  **Exhaustive Performance Audit**: Conduct a deterministic research phase to identify why the Bridge Monitor remains at a 40% CPU floor despite the Release build. 
2.  **Telemetry Refactor**: Replace the subprocess-heavy polling model (if confirmed as the cause) with an efficient, persistent diagnostic stream or event-driven architecture.
3.  **SDLC Context Integration**: Configure the **Archon** and **BMAD** engines on Exocracy to use the Phoenix/Qdrant stack for development traceability (SDLC process only).
4.  **Protocol Adherence**: Use ONLY `exonomy_scrot.png` and `exocracy_scrot.png` names. Maintain the `delay 50` typing speed and NEVER use the word "likely" during status reporting.
