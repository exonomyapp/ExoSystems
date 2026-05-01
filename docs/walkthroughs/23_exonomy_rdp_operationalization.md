# Walkthrough 23: Exonomy Remote Desktop Operationalization

This document details the successful establishment of a secure, bidirectional graphical bridge between the primary development host (Exocracy) and the federated mesh node (Exonomy). This enables direct UI automation and manual verification of node-level operations without physical presence.

## 1. Network Constraints & Connectivity Strategy

Direct RDP connections to the Exonomy node (`10.178.118.245:3389`) were failing due to network routing restrictions or firewall constraints that blocked the `freerdp` handshake. 

To bypass this, we leveraged the existing SSH capabilities (which were verified to work on port 22) to establish a localized tunnel:
```bash
# Forwarding the remote RDP port (3389) to the local loopback interface
sshpass -p "." ssh -o StrictHostKeyChecking=no -fNL 3389:localhost:3389 exocrat@10.178.118.245
```
This effectively encapsulated the Remote Desktop Protocol within a secure SSH tunnel, allowing the Remmina client to connect to `127.0.0.1:3389`.

## 2. Desktop Client Automation

To operationalize the desktop without relying on manual user intervention, we installed a suite of X11 window management tools on Exocracy:
- `xdotool`: For synthesizing keyboard and mouse events.
- `wmctrl`: For querying and managing window focus.
- `gnome-screenshot` & `scrot`: For capturing the visual state of the desktop.

### TLS Certificate Acceptance
Upon initiating the connection (`remmina -c remmina-exonomy.remmina`), the FreeRDP backend triggered an interactive GUI prompt requesting acceptance of an unverified TLS certificate. The user manually accepted this to accelerate the process, allowing the RDP session to fully render the Exonomy GNOME 46 desktop locally.

## 3. Bidirectional Flow Achieved

The infrastructure now supports:
- **CLI/Engine Sync**: Full terminal access to Exonomy for deploying `conscia` binaries via `scp` and `ssh`.
- **Graphical Operations**: Full access to the Exonomy desktop via the tunneled RDP session. 

This bridge is critical for the next phase: manually driving the Firefox browser *inside* the Exonomy node to test the Conscia dashboard's capability governance loop (Join Requests & Peer Authorization) exactly as a physical Node Operator would.
