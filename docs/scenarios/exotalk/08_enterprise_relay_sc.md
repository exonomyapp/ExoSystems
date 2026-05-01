# Screenplay 08: The Enterprise Relay

## Part 2: The Architect (Malik)

### Scene 1: Scaling Sovereignty
**Visual**: A dashboard showing multiple identities ("Amnesty Field Office", "Andes Team 1") on a single node.
**Action**: Deploying an Enterprise Conscia Relay.

**Narrator VO**: "Sovereignty scales. **Amnesty International** field workers in the Andes deploy Enterprise Relays. They handle high-volume document sync while maintaining 100% local control."

### Scene 2: The Metadata Shield
**Visual**: Logs showing zero outbound metadata to external trackers.
**Action**: Verifying the "Zero-Harvest" audit.

**Malik VO**: "No **Palantir** mapping, no **World Bank** metadata harvest. The organization coordinates, but the members remain sovereign. This is how we protect the people who protect the world."

---

## KDVV Recording Sequence
1. **Action**: `conscia deploy --preset enterprise`
2. **Visual**: `scrot_08_enterprise_relay.png`
3. **Audit**: `curl http://localhost:11434/api/admin/metrics`

---

## Technical Footer
- **Scenario Reference**: [08_enterprise_relay.md](file:///home/exocrat/code/exotalk/docs/scenarios/08_enterprise_relay.md)
- **Engine State**: Multi-tenant isolation verified, enterprise gossip config active.
