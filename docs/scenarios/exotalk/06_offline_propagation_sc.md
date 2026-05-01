# Screenplay 06: Offline Propagation

## Part 1: The Witness (Isabella)

### Scene 1: The Dark Zone
**Visual**: ExoTalk UI with "Offline" status bar.
**Action**: Writing a message (war crimes report).

**Isabella VO**: "The fiber optics are gone. They’ve cut the world off. But my report must get out. I drop it into my local vault. It’s not an email; it’s a permanent blob, waiting for a bridge."

### Scene 2: The Courier
**Visual**: A volunteer’s tablet (simulated) syncing with Isabella’s terminal over a local hotspot.
**Action**: Local P2P sync (mDNS).

**Narrator VO**: "The mesh is physical. A **Doctors Without Borders** volunteer carries the report out of the dark zone on a tablet. The moment they hit a signal, the truth propagates globally."

---

## KDVV Recording Sequence
1. **Action**: Create message in offline mode -> Sync with local "Courier" node.
2. **Visual**: `scrot_06_offline_sync.png`
3. **Audit**: `curl http://localhost:11434/api/blobs/status`

---

## Technical Footer
- **Scenario Reference**: [06_offline_propagation.md](file:///home/exocrat/code/exotalk/docs/scenarios/06_offline_propagation.md)
- **Engine State**: Store-and-forward queue active, bloom filter sync verified.
