# Screenplay 00: The Solid Front Door

## Part 1: The Witness (Isabella)

### Scene 1: The Entry
**Environment**: Exonomy Node (Clean Boot).
**Visual**: The "Welcome to ExoTalk" screen (Front Door).
**Action**: Launching the app.

**Narrator VO**: "In the war-torn regions of the Levant, communication is a battlefield. Isabella, a war crimes expert in East Jerusalem, finds her digital world closing in. **Palantir** algorithms have flagged her. Her email is a liability."

**Isabella VO**: "My credentials died an hour ago. The Insider sent a dead drop—a link to a 'Sovereign Front Door'. No login. No server. Just an opening into the mesh."

### Scene 2: The Choice
**Visual**: The Onboarding Menu (Link Device / Create Identity).
**Action**: Hovering over "ADD SOVEREIGN IDENTITY".

**Narrator VO**: "Sovereignty isn't given; it's claimed. Isabella chooses to build her presence from the ground up, outside the reach of the technocratic empire."

---

## KDVV Recording Sequence
1. **Launch**: `DISPLAY=:0 ./exotalk_flutter`
2. **Visual**: `scrot_00_front_door.png`
3. **Audit**: `curl http://localhost:11434/api/system`

---

## Technical Footer
- **Scenario Reference**: [00_solid_front_door.md](file:///home/exocrat/code/exotalk/docs/scenarios/00_solid_front_door.md)
- **Engine State**: No active identities, networking initialized (Gossip overlay active).
