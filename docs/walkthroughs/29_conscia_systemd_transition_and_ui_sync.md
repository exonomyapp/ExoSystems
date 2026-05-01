# Walkthrough 29: Conscia Systemd Transition & UI Sync

This session finalized the stabilization of the Conscia beacon on the remote Exonomy node by migrating it from a brittle background process to a robust system-level Linux service. We also performed final aesthetic synchronizations on the Conscia dashboard.

## 1. Systemd Service Formalization
We established a robust auto-restarting background service for Conscia on the Exonomy node (`10.178.118.245`), ensuring the node survives reboots and SSH session terminations.

- **Service Unit Creation:** Deployed `/etc/systemd/system/conscia.service` using `sudo`. The service runs under the `exocrat` user, binding to the `~/conscia` directory.
- **Process Stabilization:** The `ExecStart` directly targets the release-optimized `conscia` binary (`v0.7.7`), removing the need for `nohup` or `setsid` wrapping.
- **Auto-Restart:** Configured with `Restart=always` to ensure high availability for the P2P mesh and lifeline telemetry.

## 2. Legacy Storage Cleanup
To prevent future `Database already open` locking conflicts, we performed a permanent cleanup of the legacy storage mechanism.

- **Removal:** Purged the legacy `~/exotalk_storage` directory from the Exonomy node.
- **Verification:** The node now correctly provisions and exclusively utilizes the isolated `conscia_storage` directory as established in Walkthrough 28.

## 3. UI Aesthetic Synchronization
We audited the Conscia dashboard footer to ensure the visual hierarchy was perfectly aligned for professional consistency.

- **Footer Brightness Sync:** Removed the explicit `color: var(--muted)` override on the `#version-label` (`v0.7.7`).
- **Inheritance:** The version label now strictly inherits its styling directly from the parent `<footer>` container. This ensures that the version number brightness is visually identical to the surrounding copyright notice (`&copy; 2026 Conscia P2P Networking`).

## 4. API Verification
We performed an end-to-end verification of the running Systemd service.

- **Telemetry:** The `api/stats` endpoint correctly returns the node's running state (`Online`) and version (`0.7.7`).
- **Governance:** The `api/governance/requests` endpoint responds actively, proving the web server and application logic are fully operational within the systemd context.

## How to Verify
1. **Remote Dashboard:** Open `http://exonomy.local:3000` (or `http://10.178.118.245:3000`) in a browser and verify the page loads.
2. **System Status:** SSH into Exonomy and run `systemctl status conscia` to confirm the service is `active (running)`.
3. **Footer Aesthetics:** Observe the footer in the dashboard. The copyright string and the "v0.7.7" label should be perfectly matched in color and brightness.

## Next Steps
- Continue with mesh network governance testing (Petition flows).
- Monitor system logs via `journalctl -u conscia` to evaluate long-term stability and peer discovery metrics.
