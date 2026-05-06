# Walkthrough 58: SDLC Orchestration Stack Completion

## Overview
This session finalized the **Exonomy Minikube observability stack** by adding Promptfoo and ensuring all three SDLC tools (Qdrant, Arize Phoenix, and Promptfoo) are accessible to Exocracy agents via standardized Kubernetes `NodePort` services.

## Architectural Changes

### 1. Qdrant NodePort Conversion
The Qdrant vector database was previously deployed as a `ClusterIP`, rendering it unreachable to external agents. It was converted to a `NodePort` service to allow Exocracy's future LlamaIndex processes to write and read institutional memory vectors over the network.
- REST API: NodePort `32333`
- gRPC API: NodePort `32334`

### 2. Promptfoo Deployment
The third required SDLC tool, **Promptfoo**, was deployed to uphold the "Test Before Deliver" protocol for agentic LLM prompts. 
- The image was strictly pinned to the stable `ghcr.io/promptfoo/promptfoo:0.120.6` to ensure deterministic evaluation consistency without upstream breakage.
- The UI is exposed via NodePort `32300`.

### 3. Networking Protocol Verification
Minikube's Docker driver assigns the cluster an internal IP (`192.168.49.2`) bound only to the Exonomy host's bridge network. It was verified that accessing these NodePorts from Exocracy requires standard SSH port forwarding (e.g., `ssh -L`). This architectural boundary was formally documented in `[Spec 35]`.

## Deployment Artifacts
All manifests were formally versioned on the Exocracy machine at `infra/k8s/observability/` before being transferred to Exonomy's `~/deployments/k8s/observability/` path, honoring the "Exocracy is Ground Zero" rule.

## ⏭️ Next Steps
With the infrastructure layer finalized on Exonomy, the next phase will occur strictly on the **Exocracy** workstation:
1. Install the BAML CLI (`baml-cli`) and configure the first prompt schema.
2. Install the **Archon** execution engine.
3. Establish the SSH tunneling strategy for Archon to broadcast its OpenTelemetry spans to Arize Phoenix.
