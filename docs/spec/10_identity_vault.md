# Identity Vault Structure

## 10.1 IdentityVault Local Schema
The `IdentityVault` is the root record of the user's localized digital presence.

- **Storage Fields:**
  - `did: String` – The full `did:peer:2.Vz...` identifier.
  - `secret: String` – Base58 encoded Ed25519 signing secret (The "Master Key").
  - `display_name: String` – Current user alias.
  - `avatar_url: String` – Data-URI or remote URL for the profile picture.
  - `proof_string: String` – Most recently generated verification proof.
  - `verified_links: Vec<VerifiedLink>` – Records of successfully proofed third-party platforms.
  - `name_history: Vec<NameRecord>` – Chronological records of previous aliases and their proofs.
  - `linked_accounts: Vec<OAuthLink>` – Metadata for secondary "Inward Recovery" accounts (e.g., Google, GitHub).

## 10.2 Persistence and Protection
- **Local Resilience:** Serailized to `identity.json` in the application data directory.
- **In-Memory Access:** Wrapped in `Arc<RwLock<IdentityVault>>` for concurrent access by the Willow engine and Flutter UI.

## 10.3 The "Master Key" Backup Model
ExoTalk distinguishes between **Identity** and **Data** when considering resilience:

1. **Identity Backup (Master Key):**
   - The `secret` string is the absolute root of identity. Loss of this key is permanent.
   - **Manual:** Exposed in the Account Manager UI for deliberate, manual backup (e.g., to a hardware vault).
   - **Sync:** Exported in an encrypted "Profile Bundle" for peer-to-peer inheritance during device pairing.
2. **Data Persistence (Always-Present Repository):**
   - Messages and files are replicated across the Willow swarm.
   - **Lifeline Service (Premium):** On Conscia nodes, whitelisted users can enable high-availability persistence. This is not a "periodic backup" but an **always-present mirror** that ensures your entire personal repository remains reachable even when all of your own devices are offline.
