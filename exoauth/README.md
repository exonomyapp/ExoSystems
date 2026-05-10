# ExoAuth — The Universal Passport

[ 🏠 Back to Exosystem Root ](../README.md)

The `exoauth` package provides the unified **"Universal Passport"** for the entire Sovereign Exosystem. It is the "Solid Front Door" that bridges familiar user experiences with decentralized cryptographic sovereignty.

## 🛂 The Universal Passport
As demonstrated in our [Identity Synthesis](../../docs/scenarios/screenplays/01_identity_synthesis.md) screenplay with **Isabella**, ExoAuth handles the transition from standard login flows to sovereign identity:

1. **Familiar Entry**: Supports standard OAuth flows for user convenience when needed.
2. **Cryptographic Synthesis**: A unique Ed25519 keypair is synthesized locally. No central server assigns your identity; you claim it through local math.
3. **Identity Binding**: The resulting `did:peer` is cryptographically bound to the user's vault, creating a portable, sovereign passport that works across all ExoTalk products.

## Architecture & Integration
- **Pure Flutter/Dart**: A decoupled package that provides UI components and the core `ConsciaTheme`.
- **Dependency Injection**: Consuming applications inject their specific authentication callbacks to fulfill login requests.
- **Unified Experience**: Ensures that **Isabella's** identity remains consistent whether she is using ExoTalk, CMC, or Exonomy.

## 📦 Consumption
This package is consumed universally across the ecosystem's desktop and mobile apps:
- **ExoTalk Flutter**: The primary messaging client.
- **CMC (Conscia Management Console)**: For secure node administration.
- **Exonomy**: The platform shell and ecosystem storefront.
