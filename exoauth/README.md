# ExoAuth - Identity Service

[ Repository Root ](../README.md)

The `exoauth` package provides the identity service for ExoTalk. It facilitates the transition between standard authentication flows and decentralized cryptographic autonomy.

## Identity Management
ExoAuth handles the integration of standard authentication and local identity generation:

1. **Authentication Flows**: Supports standard OAuth flows for initial user authentication.
2. **Cryptographic Generation**: An Ed25519 keypair is generated locally to establish identity.
3. **Identity Binding**: The resulting `did:peer` is bound to the local identity store, creating a portable identity for use across ExoTalk components.

## Architecture & Integration
- **Flutter/Dart Package**: A decoupled package providing identity components and the `ConsciaTheme`.
- **Dependency Injection**: Consuming applications inject authentication callbacks to fulfill requests.
- **Identity Consistency**: Ensures consistent identity across ExoTalk, CMC, and Exonomy.

## Integration
This package is used across the following components:
- **ExoTalk Flutter**: Messaging client.
- **CMC (Conscia Management Console)**: Node administration interface.
- **Exonomy**: Platform shell and storefront.
