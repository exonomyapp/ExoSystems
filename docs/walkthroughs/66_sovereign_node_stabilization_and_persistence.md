# Walkthrough: Sovereign Node Stabilization & Persistence

We have finalized the architectural stabilization of the Exonomy node. This session focused on moving from ephemeral, "trial" configurations to a production-grade, boot-stable infrastructure using the **Stable v1.1.11** zrok standard.

## 1. Summary of Changes

### 1.1. Infrastructure Persistence
*   **Stable zrok v1**: Downgraded from the unstable v2 preview to the rock-solid v1.1.11 standard to enable truly permanent URL reservations.
*   **Reserved URLs**:
    *   **Signaling Relay**: `https://exotalkberlin.share.zrok.io`
    *   **Conscia Node**: `https://conscianikolasee.share.zrok.io`
*   **Systemd Services**: Configured all core components to auto-start on boot:
    *   `exotalk-signaling.service` (Port 8080)
    *   `exotalk-conscia.service` (Conscia Daemon)
    *   `exotalk-zrok.service` (Stable Relay Proxy)
    *   `exotalk-zrok-conscia.service` (Stable Node Dashboard Proxy)
    *   `minikube.service` (Observability stack)

### 1.2. API & UI Refinement
*   **CORS Implementation**: Added a permissive `CorsLayer` to the Conscia Axum server (`main.rs`) to allow external UIs (like the Bridge) to connect without `NetworkError` issues.
*   **Telemetry Standardization**: Renamed the `blob_count` metric to `storage_status` across the Rust core and Dashboard UI for improved semantic clarity.
*   **Educational Documentation**: Added "Brain" emoji educational context blocks to all modified files to align with the "Process IS The Product" mandate.

## 2. Verification Plan (Post-Reboot)

The user is about to reboot. Upon reconnection, follow this checklist:

1.  **Service Audit**:
    ```bash
    systemctl status exotalk-signaling exotalk-conscia exotalk-zrok exotalk-zrok-conscia minikube
    ```
2.  **Public Reachability**:
    *   Visit [https://conscianikolasee.share.zrok.io](https://conscianikolasee.share.zrok.io) to verify the dashboard.
    *   Verify the Signaling Relay is reachable at `https://exotalkberlin.share.zrok.io`.
3.  **Observability**:
    ```bash
    minikube status
    ```

## 3. What's Next?
- [ ] **Cross-Node Federation**: Now that we have stable URLs, we can begin hard-peering the Berlin node with other regional nodes (e.g., London or New York).
- [ ] **Bridge Monitor Integration**: Update the Flutter Bridge Monitor to point to the new `exotalkberlin` signaling URL as its default relay.
- [ ] **Commercial Readiness**: Validate the "Conscire" transaction flow over the stable tunnels.

---
*Status: Ready for Reboot Test.*
