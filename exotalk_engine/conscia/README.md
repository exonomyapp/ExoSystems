# Conscia Node — The Sovereign Lifeline

Conscia is the always-on, standalone beacon and relay daemon for the ExoTalk network. It provides archival storage, high-availability peer routing, and "Lifeline" identity recovery for users like **Charlie**, ensuring messages are delivered even when devices are offline.

## 🛡️ The Sovereign Lifeline
In the ExoTalk ecosystem, Conscia acts as your personal "Store and Forward" buffer. When you are hiking in the mountains or traveling through "dead zones," your Conscia node stays online, securely buffering encrypted messages until you reconnect.

## Deployment Levels

Conscia is designed to scale from single-user homelabs to enterprise-grade high-availability clusters. Every Conscia node anchors itself to the network by generating a unique `did:peer` identity, enabling cryptographic governance directly from ExoTalk.

### Level 1: Independent Setup (Personal Lifeline)
A guided, wizard-based deployment managed directly from within the ExoTalk application.
- Uses OAuth provisioning to instantly deploy to Google Cloud, AWS, or Oracle.
- Perfect for non-technical users looking to set up a personal archival node.
- Includes step-by-step video tutorials within the ExoTalk UI featuring **Charlie's** story.

### Level 2: Advanced High-Availability (HA)
For high-traffic, mission-critical infrastructure, Conscia supports a robust 3-Node Cluster configuration.
- **Master/Slave Topology:** One master node replicates state to two slave nodes.
- **Load Balancing:** Slave nodes actively process incoming queries and sync requests.
- **Failover:** Immediate continuity if the master node goes offline.

## 📦 Installation Methods

We strive to make installing `conscia` as native and frictionless as possible. Choose your preferred package manager.

### 1. APT Repository (Recommended for Linux)
The primary method for native Linux system-wide service integration, as shown in our [technical screenplays](../../docs/scenarios/screenplays/03_sovereign_lifeline.md).
```bash
sudo apt update && sudo apt install -y conscia
```

### 2. NPM Global Package
Ideal for developers already using Node.js toolchains.
```bash
npm install -g conscia
```

### 3. Snap Store
For sandboxed, auto-updating deployments.
```bash
sudo snap install conscia
```

### 4. Portable Binary Download
A direct download of the standalone Rust executable for minimal overhead or air-gapped systems.
```bash
curl -LO https://releases.exotalk.org/conscia/latest/conscia-linux-amd64
chmod +x conscia-linux-amd64
sudo mv conscia-linux-amd64 /usr/local/bin/conscia
```

## Bootstrapping & Configuration

Once installed, Conscia can be bootstrapped via two primary methods:
1. **The CLI:** Use the robust `conscia init` command to configure your node. The CLI is intentionally architected to follow the exact same logic and step-by-step flow as the ExoTalk Onboarding Wizard.
2. **ExoTalk Wizard:** Pair a fresh node with your ExoTalk app by scanning a generated pairing phrase or hitting the "Link Node" button.

## 🖥️ Management & Dashboard
While the `conscia` daemon is the "Heart" of the relay, it is intended to be managed via the **Conscia Management Console (CMC)**. 

- **CMC ([/cmc](../../cmc/README.md))**: A high-fidelity Flutter dashboard for orchestrating your fleet of Conscia nodes, managing capabilities, and viewing real-time telemetry.
- **Unified Logic**: Both the CLI (`conscia init`) and the CMC follow the same architectural patterns to ensure a consistent experience across terminal and GUI.

## 📚 Related Documentation
- **[Conscia Operations Guide](../../docs/conscia_ops_guide.md)**: Manual for managing and troubleshooting the daemon.
- **[Conscia Distribution Spec](../../docs/spec/conscia_distribution.md)**: Deep dive into the packaging matrix (Apt, Snap, NPM).
- **[Node Management UI Spec](../../docs/spec/conscia_manage.md)**: Details on the Top-Down node management user interface.
