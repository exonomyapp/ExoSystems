# Spec 30: Emergency Manual Operation

This specification document serves as the "Sovereign Ground Truth" for the ExoTech Bridge Monitor infrastructure. In the event of a UI failure or the absence of the AI Agent, use these hard-coded commands to manually manage the mesh daemons on the Exonomy node.

## Core Mesh Daemons

### 1. Signaling Relay
The WebRTC handshake bridge.
- **Binary Path**: `/home/exocrat/code/exotalk/infra/bin/signaling-relay`
- **Manual Start Command**:
  ```bash
  nohup /home/exocrat/code/exotalk/infra/bin/signaling-relay > ~/signaling.log 2>&1 &
  ```
- **Verification**: `pgrep -fl signaling-relay`

### 2. Conscia Beacon
The P2P Mesh engine (Sovereign).
- **Binary Path**: `/home/exocrat/code/exotalk/exotalk_engine/target/release/conscia`
- **Manual Start Command (Active)**:
  ```bash
  nohup /home/exocrat/code/exotalk/exotalk_engine/target/release/conscia daemon > ~/conscia.log 2>&1 &
  ```
- **Manual Start Command (Sleep Mode)**:
  ```bash
  nohup /home/exocrat/code/exotalk/exotalk_engine/target/release/conscia daemon --sleep > ~/conscia.log 2>&1 &
  ```
- **Verification**: `pgrep -fl conscia`

### 3. Public Proxy
The gateway for external node communication (exotalk.tech).
- **Binary Path**: `/home/exocrat/code/exotalk/infra/bin/exotalk-proxy`
- **Manual Start Command**:
  ```bash
  nohup /home/exocrat/code/exotalk/infra/bin/exotalk-proxy > ~/proxy.log 2>&1 &
  ```
- **Verification**: `pgrep -fl exotalk-proxy`

## Maintenance Procedures

### Port Cleanup
If a daemon fails to start due to "Address already in use," identify and kill the process holding the port:
```bash
# Example for Signaling (8080)
fuser -k 8080/tcp
```

### Log Inspection
All manual daemons redirect output to log files in the home directory (`~/`):
- `tail -f ~/signaling.log`
- `tail -f ~/conscia.log`
- `tail -f ~/proxy.log`

---
**Standard**: KDVV (Keystroke-Driven, Visual-Verified)
**Status**: ACTIVE
