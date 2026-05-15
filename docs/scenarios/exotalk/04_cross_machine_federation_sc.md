# Screenplay 04: Cross-Machine Federation

## Part 3: The Orchestrator (Zayd)

### Scene 1: The Hangzhou Bridge
**Visual**: Dual terminal view (Hangzhou Node / Beirut Node).
**Action**: Initiating federation handshake.

**Narrator VO**: "**Zayd**, in his hub in **Hangzhou**, sees the pressure building on Malik’s Beirut relay. US-led sanctions are targeting Lebanese infrastructure, trying to isolate the defenders."

**Zayd VO**: "They think they can freeze us out by controlling the Western gatekeepers. They are wrong. I am federating my Hangzhou cluster with Beirut. My backbone is now their backbone."

### Scene 2: The Global Sync
**Visual**: Message replication logs showing Hangzhou mirroring Beirut data.
**Action**: Sending a test message through the federated link.

**Narrator VO**: "Autonomy without isolation. The mesh bypasses the blockade, linking disparate loyalties into a single, unassailable truth-layer."

---

## KDVV Recording Sequence
1. **Action**: `conscia federate --peer <hangzhou_ip>`
2. **Visual**: `scrot_04_federation_sync.png`
3. **Audit**: `curl http://localhost:11434/api/federation`

---

## Technical Footer
- **Scenario Reference**: [04_cross_machine_federation.md](04_cross_machine_federation.md)
- **Engine State**: Meadowcap delegation complete, Iroh gossip synced.
