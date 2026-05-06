# Walkthrough 57: Bridge Monitor Localization & Legislator Stabilization

## Overview
This session finalized the transition of the Bridge Monitor from a remote administration tool to the native, local "Legislator" of the Exonomy node. We diagnosed and resolved the stubborn "bounce-back" issue where toggling nodes off in the UI failed to actually stop the services.

## 1. Purging SSH Drift & Enforcing Local Jurisdiction
The core problem was traced to legacy code from when the Bridge Monitor was executed remotely from Exocracy.

### The Root Cause (The "Bounce-Back" Issue)
When toggling a node off (e.g., Signaling Relay or Public Proxy), the Monitor executed:
`sshpass -p "." ssh exocrat@exonomy.local systemctl --user stop ...`

Since the Monitor is now natively deployed on Exonomy, `sshpass` is not installed on the system. 
1. The remote SSH command failed silently.
2. The background daemon continued running.
3. The next 5-second `TelemetryUtil` `pgrep` poll detected the active daemon and immediately forced the UI back to green (ON).

### Resolution
We removed all `sshpass` wrappers from `main.dart`. The Monitor now issues native `systemctl --user ...` commands directly to the local host. As the true "Legislator" of the node state, when the Monitor says "stop", the systemd services are gracefully shut down.

## 2. Validating the Conscia "Observer Model"
We identified why the Conscia "Sleep" state was the only one that did not refuse:
- In the original code, the Sleep state UI update intentionally bypassed the `TelemetryUtil` polling check. 
- Because the `sshpass` stop command failed silently, the Conscia process remained active in the background. This inadvertently fulfilled the intended "Observer Model" by pure accident.

We have formalized this logic in `_setNodeState`:
- **State 0 (Off):** Properly issues `systemctl --user stop exotalk-conscia`.
- **State 1 (Sleep):** Deliberately issues *no* stop command, allowing the UI to reflect a sleeping state while leaving the daemon fully active to serve background tasks, properly honoring the Observer Model.

## 3. UI Parity & Version Increment
- **Row/Card Parity Checked:** Because both the Grid View cards and the List View rows point to the same unified `_setNodeState` and `_cycleConscia` functions (as finalized in Walkthrough 56), the stabilization applies equally to both viewing modes.
- **Build Tag Updated:** The UI string was updated from `v1.1.6-HEARTBEAT` to `v1.1.7-LEGISLATOR`.
- **Release Build:** The `flutter build linux --release` process completed successfully.

## ⏭️ Next Steps
- **KDVV Deployment:** Transfer the newly built `v1.1.7-LEGISLATOR` bundle to the Exonomy desktop.
- **Visual Verification:** Trigger the toggles in both Grid and Row views via the desktop to confirm the systemd services definitively stop and stay off.
- **P2P Handshake Audit:** Proceed with the `signaling_server.py` SDP/ICE instrumentation.
