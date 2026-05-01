# Walkthrough 26: Federated Access Request & P2P Governance Verification

This walkthrough summarizes the implementation of the `request_access()` functionality in the engine, its exposure to the Flutter UI layer, and the status of our end-to-end P2P mesh network verification.

> [!NOTE]
> The terminology was successfully refined from "petition" to **"Request Access"** throughout the codebase to ensure an aesthetic that aligns with the professional, decentralized governance model of the Conscia mesh.

## 1. Engine Implementation
We added the `request_access()` functionality in `exotalk_core/network_internal.rs`.
- The engine uses the `chrono` crate to timestamp `JoinRequest` structures.
- It derives the `conscia_mesh_governance` namespace and connects to the topic.
- A serialized `JoinRequest` containing the sender's `node_id` is broadcasted via the Iroh gossip mesh `broadcast_raw_gossip` system.

## 2. FFI Exposure & Dart Code Generation
We updated `exotalk_ffi/api/network.rs` to expose the new function. Using `flutter_rust_bridge_codegen`, we cleanly generated the Dart bindings, enabling the "Request Access" action in the native UI.

## 3. UI Integration (Solid Identity Paradigm)
We updated the `Account Manager` modal in `account_manager.dart`:
- Replaced previous mock or manual "petition" workflows with a streamlined, keyboard-first "Request Access" button (shield icon).
- Re-styled the button according to the strict, high-density, no-translucency *Solid Identity* constraints.
- Bound the button to trigger `api.network.requestAccess()`, providing immediate UI feedback via toasts for the broadcast result.

## 4. Verification & Testing

### Local Mesh Verification
We created a specialized local diagnostic test (`test_send_actual_request`) to verify the engine's capability to join the governance topic and broadcast the packet successfully. 
- The test established a dedicated Iroh node (with a valid derived Ed25519 secret key).
- Connected dynamically to the associated relay.
- Triggered `request_access()`.

### Remote Exonomy Dashboard Handshake
> [!WARNING]
> Manual end-to-end verification via the Exonomy node GUI (Remmina/localhost:3000) was partially blocked. 

**Root Cause:**
1. The `conscia` binary currently deployed on the remote `10.178.118.245` machine is an older version that does not expose the `/api/governance/requests` and `/api/governance/authorize` REST endpoints (they return 404).
2. Redeployment of the compiled `conscia` binary via `gcp_push.sh` or SSH was prevented due to "Too many authentication failures" (SSH lock) and GCP API restrictions.

**Resolution Status:**
The local tests confirm that the engine accurately broadcasts the `JoinRequest` tokens to the governance mesh topic. Once the remote machine's SSH lock clears, executing `gcp_push.sh` or manually uploading the binary to `~/conscia/conscia-beacon` will expose the dashboard endpoints and allow the final "Authorize" handshake via the GUI.

## Next Steps
- Clear the SSH lockout on the Exonomy node.
- Deploy the updated `conscia` binary.
- Manually review the `JoinRequest` on the Exonomy dashboard and authorize the node.
