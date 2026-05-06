# Walkthrough 52: Exonomy Minikube Observability Baseline & Visual Protocol Enforcement

## Overview
This session focused on transitioning the **Exonomy node** to a clean Docker environment to support the **Minikube SDLC observability stack**, while strictly enforcing a new pedagogical **Strict Visual Interactive Protocol**.

## Architectural Adjustments

### 1. Strict Visual Interactive Protocol (`agent.md`)
The core operational guidelines were updated to strictly enforce observability for all automated actions:
- **Anti-Silent-Fix Rule**: Prohibits background or silent fixes for configuration/infrastructure problems. All fixes must be typed and executed visually in front of the user via `xdotool`.
- **Visual Verification**: Mandates that after executing a command visually, a screenshot (`scrot`) must be taken to verify the actual output. 
- **Window Focus Requirement**: Specifically, before capturing the screenshot, `wmctrl -i -a <WID>` must be used to bring the terminal window to the front, preventing capture of obscured windows.
- **Regression Protocol ("Again" rule)**: Formalized a high-priority architectural audit requirement whenever the user indicates a repeat issue.

### 2. Docker Daemon Stabilization
The default Ubuntu `docker.io` package possessed a corrupted post-installation script that threw an exit status 5 (`nuke-graph-directory.sh` calling `docker stop` when no service existed), trapping the system in a broken package state.
- **Resolution**:
  - `docker.io` pre-removal scripts were manually neutralized (`rm -f /var/lib/dpkg/info/docker.io.prerm /var/lib/dpkg/info/docker.io.postrm`).
  - The package was forcefully purged.
  - The official `docker-ce` repository was added, and `docker-ce`, `docker-ce-cli`, and `containerd.io` were cleanly installed.
  - User `exocrat` was added to the `docker` group, and permissions were finalized with `newgrp docker`.

### 3. Minikube SDLC Provisioning
With a stable Docker foundation, Minikube was provisioned to serve as the decentralized infrastructure layer for observability.
- **Initial Attempt**: Encountered a profile conflict where Minikube attempted to reuse an old cluster profile, ignoring the requested resource limits and eventually failing with `K8S_APISERVER_MISSING`.
- **Final Provisioning**: The corrupted cluster was purged (`minikube delete`), and the new cluster was successfully initialized:
  ```bash
  minikube start --driver=docker --cpus=4 --memory=8192
  ```

## Validation & Results
- **System Package State**: Clean. `dpkg --audit` reports no broken packages.
- **Kubernetes State**: Minikube is actively running with 4 CPUs and 8GB RAM, ready to receive the vector memory (Qdrant) and observability (Arize Phoenix) pods.
- **Protocol Enforcement**: The new visual protocols guarantee that the user maintains complete supervisory visibility over all subsequent infrastructure deployment steps.

## Next Steps
Proceed to Phase 2: Deploy Qdrant and Arize Phoenix onto the running Minikube cluster using the pre-researched security and resource configurations.
