# 11. Meadowcap Capability Format

## 11.1 The Delegation Chain Architecture
ExoTalk utilizes a decentralized permissioning system powered by Meadowcap capabilities. True decentralization necessitates that group Admins can operate autonomously, even when the namespace Owner is offline.
- **Power of Attorney:** If Isabella (Owner) grants Malik (Admin) a capability, Malik receives mathematical "Power of Attorney". Malik can independently issue capabilities to invite a volunteer using his own local key.
- **Delegation Chains:** The volunteer's right to access the namespace is verified via a cryptographic chain: `[Isabella -> Malik] + [Malik -> Volunteer]`. Any peer can independently verify this chain by sequentially checking the Ed25519 signatures.
- **1-on-1 Symmetry:** There is no distinction between a direct message and a 100-person group. 1-on-1s utilize the exact same capability exchange, keeping the protocol unified and allowing a 1-on-1 to seamlessly evolve into a multi-user group if a 3rd capability is minted.

## 11.2 Automated Prune-and-Promote Revocation
Revocation in a chain creates a cascading effect: if Malik's capability is revoked, the volunteer's mathematically dies with it. To prevent collateral UX disruption for innocent underlings:
1. When Isabella revokes Malik, her client orchestrates an automated "Prune and Promote" maneuver.
2. It audits all public capabilities previously issued by Malik in the given namespace.
3. It recursively auto-generates brand new, direct capabilities (e.g., `Isabella -> Volunteer`) to rescue the innocent members.
4. It gossips these rescue tokens concurrently with Malik's tombstone, shifting the network graph instantly.

## 11.3 Technical Structure
- **Capability struct**: `Capability { delegator: Did, delegatee: Did, namespace: NamespaceId, permission: PermissionLevel, signature: Vec<u8> }`
- **PermissionLevel enum**: `Read`, `Write`, `Admin` (where `Admin` explicitly implies `can_delegate` rights).
- **Signing**: The delegator signs the serialized capability using their local Ed25519 private key.
- **Transport**: Capabilities are exchanged as JSON blobs over the Iroh gossip channel during the initial peer handshake, and stored in a dedicated `capabilities/` Willow namespace.
- **Revocation**: Revocation is performed by publishing a tombstone entry (`revoked: true`) targeting the original capability hash.

## 11.4 Federated Join Requests
- **JoinRequest struct**: `JoinRequest { node_id: Did, timestamp_ms: i64 }`
- **Workflow**: 
    1. A new node broadcasts a `JoinRequest` JSON to the `conscia_mesh_governance` topic.
    2. The Conscia beacon (operating in Federation mode) receives the request and queues it for the operator.
    3. The operator reviews the request on the dashboard and authorizes the node, which triggers a `Capability` delegation broadcast.
- **Trust Model**: This provides a human-in-the-loop gate for joining private meshes while maintaining decentralized enforcement.
