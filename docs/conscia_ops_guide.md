# Conscia Operations Guide

This document explains how to manage, build, and run the Conscia Beacon node across multiple machines.

> [!NOTE]
> For core architectural details, high-availability cluster specifications, and native package manager installation instructions (APT, NPM, Snap), please refer to the **[Conscia Engine README](../conscia/README.md)**.

## Two Ways to Run Conscia

### 1. The Developer Way (`cargo run`)
Best for when you are making changes or testing new fixes.
- **Requirement:** Must have Rust installed and the full source code folder.
- **Command:** 
  ```bash
  cd ~/code/exotalk/exotalk_engine
  cargo run --bin conscia
  ```
- **How it works:** It checks the source code, recompiles any changes (like HTML or Rust fixes), and starts the server.

### 2. The Portable Way (`./conscia`)
Best for "Always-On" nodes or laptops where you don't want to install development tools.
- **Requirement:** Only the single `conscia` binary file.
- **Command:**
  ```bash
  ./conscia
  ```
- **How it works:** It runs a pre-compiled version of the app. It is fast and self-contained, but it won't see any code changes made after it was built.

---

## Moving Fixes to Another Machine

If you have made a fix on your development machine and want it on your portable laptop:

1. **Build a "Release" version** (this makes it fast and small):
   ```bash
   cd ~/code/exotalk/exotalk_engine
   cargo build --release --bin conscia
   ```
2. **Locate the binary:**
   The file is created at: `exotalk_engine/target/release/conscia`
3. **Copy the file:**
   Use a USB drive, `scp`, or a cloud drive to move that single `conscia` file to your other laptop.
4. **Run it:**
   On the other laptop, just run `./conscia`.

---

## Remote Access (The Tunnel Trick)

If you want to run the **Developer version** on your main machine but see the dashboard on your **other laptop**:

1. On your **other laptop**, connect via SSH with a "Tunnel":
   ```bash
   ssh -L 3000:localhost:3000 user@dev-machine-ip
   ```
2. While inside that SSH session, run the app:
   ```bash
   cd ~/code/exotalk/exotalk_engine
   cargo run --bin conscia
   ```
3. Open the browser on your **other laptop** to `http://localhost:3000`. 

The dashboard will appear on your laptop, even though the engine is actually running on your development machine.

## Remote Administration (from Exocracy)

If you are on your **Exocracy** dev machine and need to manage the **Exonomy** node without opening a full desktop:

### 1. Launching the Beacon
If the Conscia beacon is stopped on Exonomy, you can launch it remotely via systemd:
```bash
sshpass -p "." ssh -o PubkeyAuthentication=no -o StrictHostKeyChecking=no exocrat@exonomy.local "sudo systemctl start conscia"
```

### 2. Checking Logs
To see what is happening on the remote node in real-time using the systemd journal:
```bash
sshpass -p "." ssh -o PubkeyAuthentication=no -o StrictHostKeyChecking=no exocrat@exonomy.local "journalctl -u conscia -f"
```

### 3. Stopping the Beacon
To gracefully stop the remote systemd service:
```bash
sshpass -p "." ssh -o PubkeyAuthentication=no -o StrictHostKeyChecking=no exocrat@exonomy.local "sudo systemctl stop conscia"
```

---

### 2. Graphical Remote Desktop (RDP)

If you need to see the full Exonomy desktop (to run Firefox or check system settings):

1.  **Open the RDP Tunnel**: Direct RDP traffic is often blocked. Use SSH to bridge it (Credentials: `exocrat` / `.`):
    ```bash
    # Forward port 3389 (RDP) through SSH
    sshpass -p "." ssh -o StrictHostKeyChecking=no -fNL 3389:localhost:3389 exocrat@10.178.118.245
    ```
2.  **Launch Remmina**: Open the pre-configured profile on your machine. If prompted for a password inside Remmina, use `.`:
    ```bash
    remmina -c ~/exonomy.remmina &
    ```

> [!TIP]
> For historical context on how this bridge was established and verified, see [Walkthrough 23: Exonomy Remote Desktop Operationalization](walkthroughs/23_exonomy_rdp_operationalization.md).

---

## Pro Workflow: Sync & Federation

If you want to run a separate node on your laptop but keep it in sync with your dev work:

### 1. Syncing the Binary (rsync)
On your **Dev Machine**, use this command to build and "push" the app to your laptop:
```bash
# Enter the engine directory
cd ~/code/exotalk/exotalk_engine

# Build the optimized binary
cargo build --release --bin conscia

# Sync it to the laptop (replace user and ip)
rsync -avzP target/release/conscia user@laptop-ip:~/conscia
```

### 2. The Federation Handshake (Meadowcap)
To link nodes so they share gossip namespaces and provide high-availability backup:

1.  **Obtain Node ID**: Start Conscia on both machines. Copy the **Node ID** from the Laptop's dashboard or console.
2.  **Associate via ExoTalk**: Open ExoTalk on your main device. Use the **Conscia Nodes** sidebar to add the Laptop's Node ID.
3.  **Delegate Capabilities**: Navigate to the **Node Management** dashboard for the new node.
4.  **Authorize**: In the **Capabilities** section, grant the Laptop node a role (e.g., **WRITER** or **ADMIN**). This generates a Meadowcap token that authorizes the laptop to participate in your mesh.

Both nodes are now federated. You can monitor their shared health via the **Governance Mission Control** in ExoTalk.

---

## Architectural Vision: The ConSoul Node Dashboard

When architecting the administrative interface for Conscia, it is tempting to follow traditional SaaS patterns and build two distinct dashboards: a simple one for end-users, and a complex one for sys-admins. In our decentralized, P2P ecosystem, **we enforce a ConSoul UI strategy driven by Progressive Disclosure.**

### 1. The "Level-Up" Pathway
In a decentralized world, today's end-user is tomorrow's mesh network operator. Splitting the UIs creates an intimidating wall. A unified UI allows users to naturally "level up." They start by viewing simple node health statistics. As they learn more, or as their cryptographic authority increases, new advanced tools organically appear within the interface they already know.

### 2. Capability-Driven Interfaces
The UI dynamically shapes itself based on the user's Meadowcap capabilities. If a user connects to a node and their highest capability is `Read`, the Operational Pulse tabbed interface only shows basic health and uptime. If their capability is `Admin`, the UI unlocks the robust sys-admin panes—granular capability delegation, raw terminal logs, network relay configuration, etc. The interface is a mathematical reflection of the user's cryptographic authority.

### 3. Reduced Maintenance Burden
Building and maintaining separate robust dashboards—one standalone HTTP dashboard for Conscia, and one embedded Flutter view in ExoTalk—means maintaining two divergent codebases for the exact same underlying FFI/Rust logic. The unified approach ensures feature parity across the ecosystem without duplicate effort.

### 4. Advanced Network Tooling
For deep-level configurations that pertain strictly to how Conscia interfaces with the outside world (which might confuse a non-technical user even if they are the Admin of their local node), those specific panes are hidden behind a simple `[ ] Enable Advanced Network Tooling` toggle in the app settings. This keeps the default experience clean while providing full accessibility to serious sys-admins.

By leveraging a robust multi-pane (or tabbed) interface, we pack the full power of a sys-admin terminal directly into ExoTalk, keeping complex features mathematically invisible to anyone without the authority to use them.

---

## Troubleshooting

### "Database already open"
If you see this error, another Conscia process is likely using the storage directory.
- **Fix:** `pkill conscia` and restart.

### "Identity Verification Failed"
This happens if the time on your nodes is out of sync, causing Meadowcap tokens to appear "from the future" or "expired."
- **Fix:** Ensure both machines are using NTP sync.

