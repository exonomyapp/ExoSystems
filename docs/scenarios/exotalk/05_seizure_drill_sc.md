# Screenplay 05: The "Seizure" Drill

## Part 2: The Architect (Malik)

### Scene 1: The Raid
**Visual**: A "Node Disconnected" alert in the UI.
**Action**: Simulating a node seizure (killing a process).

**Narrator VO**: "Malik simulates a nightmare scenario—a node seizure by an adversary armed with **Palantir's Foundry**. Usually, this is the end of the line. But in the Exosystem, failure is a signal."

### Scene 2: Cauterization
**Visual**: The remaining nodes showing "Peer Revoked" and data migrating to the secondary relay.
**Action**: Automated Meadowcap revocation.

**Malik VO**: "The moment they take a node, the mesh cauterizes the wound. The keys are revoked. The data has already migrated to **Zayd’s** mirrors in Hangzhou. The adversary has captured an empty shell."

---

## KDVV Recording Sequence
1. **Action**: Stop node process + trigger revocation script.
2. **Visual**: `scrot_05_cauterization.png`
3. **Audit**: `curl http://localhost:11434/api/identity/revocations`

---

## Technical Footer
- **Scenario Reference**: [05_seizure_drill.md](file:///home/exocrat/code/exotalk/docs/scenarios/05_seizure_drill.md)
- **Engine State**: Instrumentalized resilience triggered, state migration verified.
