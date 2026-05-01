# Screenplay 07: Competitive Loyalty

## Part 3: The Orchestrator (Zayd)

### Scene 1: The Imperial Friction
**Visual**: A map view (simulated/dashboard) showing Hangzhou and Frankfurt nodes.
**Action**: Configuring regional mirroring.

**Zayd VO**: "I instrumentalize the friction between empires. My data is mirrored in Hangzhou and Frankfurt. If the **US Treasury** leans on one provider, the other stands. Their competing loyalties are our uptime."

### Scene 2: The Blockade Failover
**Visual**: Simulating a provider blockade on the Frankfurt node.
**Action**: Automatic traffic steering to Hangzhou.

**Narrator VO**: "Competitive loyalty as a geopolitical shield. The signal doesn't die; it just shifts to the side of the conflict that the adversary cannot touch."

---

## KDVV Recording Sequence
1. **Action**: `conscia set-mirror --region hangzhou --region frankfurt`
2. **Visual**: `scrot_07_mirror_active.png`
3. **Audit**: `curl http://localhost:11434/api/orchestration/failover`

---

## Technical Footer
- **Scenario Reference**: [07_competitive_loyalty.md](file:///home/exocrat/code/exotalk/docs/scenarios/07_competitive_loyalty.md)
- **Engine State**: Multi-region federation active, automatic failover enabled.
