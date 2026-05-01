# Screenplay 03: The Local Relay

## Part 2: The Architect (Malik)

### Scene 1: The Bunker
**Visual**: A separate terminal window showing Conscia logs (`CONSCIA_LOGS`).
**Action**: Launching a Conscia node on a solar-powered relay.

**Narrator VO**: "Malik works from a solar-powered bunker in Beirut. He knows that sovereignty requires infrastructure. He initializes a Conscia node—not to join a corporate cloud, but to act as a community anchor."

### Scene 2: The Link
**Visual**: Isabella’s ExoTalk client binding to Malik’s relay.
**Action**: Configuring the "Primary Relay" in settings.

**Malik VO**: "My node is her lifeline. When the state cuts the fiber, the messages remain. We don't need their permission to stay online."

---

## KDVV Recording Sequence
1. **Action**: `docker-compose up` (or binary run) for Conscia node.
2. **Visual**: `scrot_03_local_relay.png`
3. **Audit**: `curl http://localhost:11434/api/status`

---

## Technical Footer
- **Scenario Reference**: [03_local_relay.md](file:///home/exocrat/code/exotalk/docs/scenarios/03_local_relay.md)
- **Engine State**: Conscia relay active, mDNS advertising enabled.
