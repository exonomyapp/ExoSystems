# Walkthrough: Node Stabilization & Persistence

The architectural stabilization of the Exonomy node has been completed. The infrastructure utilizes the **Stable v1.1.11** zrok standard for persistent configurations.

## 1. Summary of Changes

### 1.1. Infrastructure Persistence
*   **zrok v1.1.11**: Utilized the v1.1.11 standard for permanent URL reservations.
*   **Reserved URLs**:
    *   **Signaling Relay**: `https://exotalkberlin.share.zrok.io`
    *   **Conscia Node**: `https://conscianikolasee.share.zrok.io`
*   **Systemd Services**: Configured components for automatic start on boot:
    *   `exotalk-signaling.service` (Port 8080)
    *   `exotalk-conscia.service` (Conscia Daemon)
    *   `exotalk-zrok.service` (Relay Proxy)
    *   `exotalk-zrok-conscia.service` (Node Dashboard Proxy)
    *   `minikube.service` (Observability stack)

### 1.2. API & UI Refinement
*   **CORS Implementation**: Added a `CorsLayer` to the Conscia Axum server (`main.rs`) to allow external UI connections.
*   **Telemetry Standardization**: Renamed the `blob_count` metric to `storage_status` in the Rust core and Dashboard UI.
*   **Educational Documentation**: Added technical context blocks to all modified files.

## 2. Verification Plan (Post-Reboot)

Follow this checklist upon system reconnection:

1.  **Service Audit**:
    ```bash
    systemctl status exotalk-signaling exotalk-conscia exotalk-zrok exotalk-zrok-conscia minikube
    ```
2.  **Public Reachability**:
    *   Verify the dashboard at [https://conscianikolasee.share.zrok.io](https://conscianikolasee.share.zrok.io).
    *   Verify the Signaling Relay at `https://exotalkberlin.share.zrok.io`.
3.  **Observability**:
    ```bash
    minikube status
    ```

---
**Status**: Implementation complete.
