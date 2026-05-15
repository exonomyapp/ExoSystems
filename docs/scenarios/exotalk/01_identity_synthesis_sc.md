# Screenplay 01: Identity Synthesis

## Part 1: The Witness (Isabella)

### Scene 1: The Void
**Visual**: Empty Account Manager Modal.
**Action**: Clicking "CREATE IDENTITY" -> "Create New Identity".

**Isabella VO**: "It’s empty. A void. Usually, there’s a 'Profile' already waiting for me, pre-loaded with metadata harvested by the **IMF** or the **World Bank**. Here, there is only what I create."

### Scene 2: The Birth
**Visual**: The "Security Vault" with empty Identifier.
**Action**: Clicking **"Synthesize"**.

**Narrator VO**: "With a single cryptographic synthesis, a unique Ed25519 keypair is born. This did:peer string is Isabella's new digital passport—calculated locally, owned entirely. It wasn't assigned by a central authority; it was claimed."

### Scene 3: The Commitment
**Visual**: Typing "Isabella" into the name field and clicking **"Initialize Identity"**.
**Action**: Transition to Home Screen.

**Isabella VO**: "I'll keep my name. But the keys are mine now. I am no longer a line item in their database. I am an independent node."

---

## KDVV Recording Sequence
1. **Action**: `xdotool click` on Synthesize.
2. **Visual**: `scrot_01_identity_synthesis.png`
3. **Audit**: `curl http://localhost:11434/api/identity`

---

## Technical Footer
- **Scenario Reference**: [01_identity_synthesis.md](01_identity_synthesis.md)
- **Engine State**: Active DID generated, Vault saved to local disk.
