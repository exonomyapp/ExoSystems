# Walkthrough: Exonomy Node Stabilization & The Enterprise FHS Pivot

**Date**: May 10, 2026

## 1. Exonomy Node Baseline Restoration
The session began by addressing race conditions and pathing errors on the Exonomy node that prevented the `exotalk-signaling` and `minikube` services from starting correctly on a fresh boot.

- **Minikube Fix**: Reconfigured the systemd unit to natively orchestrate with the Docker daemon using `Requires=docker.service docker.socket` and `After=docker.service`, eliminating the need for arbitrary sleep hacks.
- **Signaling Fix**: Corrected the `WorkingDirectory` and `ExecStart` paths in the systemd unit to correctly point to the `~/deployments/` architecture instead of the local `~/code/` boundaries.
- **Verification**: A forced remote reboot successfully proved that Minikube and Docker now initialize flawlessly without race conditions, and all services (`conscia`, `zrok`, `signaling`) start automatically.

## 2. Environmental Hygiene Refinement
The `agent.md` Housekeeping Protocol was aggressively expanded. The protocol now dictates:
- Cleanups are strictly restricted to files explicitly generated during the *current* session.
- "Sweeping" deletions based on assumptions about pre-existing files are strictly forbidden.
- Remote node cleanup must occur via SSH execution of `gio trash` to ensure reversibility via the Ubuntu desktop trash mechanism, forbidding destructive protocols like SFTP deletes.

## 3. The "Process IS The Product" Pivot
An attempt was made to manually migrate the Exonomy node deployments from `~/deployments/` to Enterprise FHS directories (`/opt/exo/`, `/etc/exo/`, `/var/exo/`) using a temporary SSH shell script. 

This approach was halted and fully rolled back because it violated the foundational architectural mandate: **"Process IS the Product"**. 

**Resolution**: We cannot act as system administrators hacking a server into compliance. The software itself must be the installer.
The agenda has officially pivoted: We will engineer automated, standardized installation technologies (e.g., native `.deb` packages and universal `Makefiles`) that automatically generate the `/opt/exo/` directories, isolate the `exo-sys` user, and register systemd units upon execution across any targeted platform. 

The immediate next phase will focus on generating the formal architectural specifications for these automated FHS installers in the `docs/releases/` directory.

---
# 🧠 EDUCATIONAL CONTEXT: Enterprise FHS Standardization
# Moving from user-space (~/deployments/) to /opt/exo/ and exo-sys 
# ensures that the infrastructure is deterministic, secure, and 
# adheres to professional Linux standards across all nodes.
