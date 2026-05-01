# Screenplay 02: Discovery without Directory

## Part 1: The Witness (Isabella)

### Scene 1: The Blackout
**Visual**: Home Screen with "Searching for Peers..." animation.
**Action**: Activating the Gossip overlay.

**Narrator VO**: "**Amnesty International** reports a nationwide internet throttling event. The fiber is being strangled. In a centralized world, Isabella would be isolated. But here, the mesh is tactile."

### Scene 2: The Handshake
**Visual**: A peer avatar ("The Insider") appearing in the sidebar.
**Action**: Real-time discovery via mDNS/Gossip.

**Isabella VO**: "He’s here. I didn't search a global index or ask a server for his location. Our nodes found each other through the flicker of the local network. We are connected, and they don't even know we're talking."

---

## KDVV Recording Sequence
1. **Action**: Start gossip service on two nodes.
2. **Visual**: `scrot_02_peer_discovery.png`
3. **Audit**: `curl http://localhost:11434/api/peers`

---

## Technical Footer
- **Scenario Reference**: [02_discovery_without_directory.md](file:///home/exocrat/code/exotalk/docs/scenarios/02_discovery_without_directory.md)
- **Engine State**: Gossip overlay active, Iroh endpoint verified.
