# Walkthrough 33: Dynamic Node Management & Sidebar Integration

This walkthrough documents the full productionization of the Conscia Node Management UI — transitioning from static placeholders to a live, data-driven architecture natively integrated into the ExoTalk sidebar.

## Summary of Changes

### 1. Conscia Data Layer (`conscia_provider.dart`)

Two new providers were added:

- **`peerListProvider`** — `FutureProvider<List<PeerInfo>>` — polls the Rust engine via `getPeerList()` to return the live roster of federated nodes. Invalidate it after adding a node to trigger a sidebar refresh.
- **`selectedNodeIdProvider`** — `StateProvider<String?>` — tracks which specific node is currently selected. `null` means no node is active.

### 2. Sidebar — `_SidebarContent` in `home_screen.dart`

The static "Manage Roster" tile has been replaced with a fully dynamic list:

- **Live peer list**: The "Conscia Nodes" `ExpansionTile` now consumes `peerListProvider` and renders one `ListTile` per node. Each tile displays the node's ID in monospace, truncated with ellipsis. Loading and error states are handled gracefully.
- **Selection highlighting**: The active node tile is visually highlighted using `ConsciaTheme.selection(context)`, consistent with how the active chat is highlighted.
- **Add Node icon**: The `ExpansionTile` trailing area is a custom `Row` containing a `+` icon (`LucideIcons.plus`, accent-colored, with "Add Node" tooltip) and the expand/collapse chevron. Tapping the `+` opens `_AddNodeDialog`.
- **`_AddNodeDialog`**: An inline `AlertDialog` with a monospace `TextField`. On confirm, it calls `associatedConsciaProvider.associateNode()` and invalidates `peerListProvider` to refresh the list.

### 3. Node Management View (`node_management_view.dart`)

Complete rewrite of the view, now fully data-driven:

- Receives the selected node via `ref.watch(selectedNodeIdProvider)` and `peerListProvider`.
- Shows a contextual empty state ("Select a node from the sidebar") when no node is chosen.
- When a node is selected, renders three section cards:
  - **Status** — reads `consciaStatusProvider` to check if the node ID matches the connected node, showing live Connected/Unreachable indicator.
  - **Addresses** — lists all known peer addresses from `PeerInfo.addresses`.
  - **Capabilities** — placeholder for Meadowcap delegation details; includes "Revoke All Capabilities" danger action.
- The "Link Node" button has been removed from the main view entirely. The add-node entry point is now exclusively the `+` icon in the sidebar header.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | ✓ 0 errors (3 pre-existing `avoid_print` info-level warnings) |
| `flutter build linux --debug` | ✓ `Built build/linux/x64/debug/bundle/exotalk_flutter` |
