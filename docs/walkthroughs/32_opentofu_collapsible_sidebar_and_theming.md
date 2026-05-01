# Walkthrough 32: OpenTofu Migration, Collapsible Sidebar & Centralized Theming

This walkthrough documents three architectural refinements: adopting OpenTofu as the official IaC tool, replacing the node management modal with a native sidebar-integrated view, and centralizing version theming discipline.

## 1. Infrastructure: Terraform → OpenTofu

After evaluating Terraform, Pulumi, and OpenTofu against the ExoTalk vision of enabling non-technical users to provision sovereign Conscia servers on cloud providers:

- **Pulumi** was eliminated because it would force a third programming language (TypeScript/Go) into our Dart/Rust monorepo.
- **Terraform** was eliminated due to HashiCorp's BSL license change, which conflicts with ExoTalk's sovereign, open-source ethos.
- **OpenTofu** was selected as the winner: it is the Linux Foundation's open-source fork of Terraform, fully compatible with the existing provider ecosystem (GCP, AWS), uses declarative HCL (no stack fragmentation), and guarantees open governance.

**Change:** Renamed `infra/terraform/` → `infra/opentofu/`. The `main.tf` and `variables.tf` files are unchanged in content; only the directory reflects our commitment to OpenTofu.

## 2. Node Management: Modal → Sidebar-Integrated View

The previous modal-based node management was a poor UX decision. Node management is a core operational concern, not an ephemeral dialog. It now lives natively in the sidebar and main content area.

### Changes Made
- **Deleted** `lib/widgets/modals/node_management_modal.dart` — the modal artifact.
- **Created** `lib/screens/node_management_view.dart` — a full-screen view that renders in the main content area (where the chat window sits) when a Conscia node is selected from the sidebar.
- **Modified** `lib/screens/home_screen.dart`:
  - Added `MainView` enum and `activeMainViewProvider` to track whether the user is viewing a Chat or the Node Management screen.
  - Replaced the flat `_ConversationList` with `_SidebarContent`, which contains two collapsible `ExpansionTile` groups:
    1. **Chats** — the conversation list (collapsible).
    2. **Conscia Nodes** — the node roster with a "Manage Roster" entry (collapsible).
  - Collapsing one group frees vertical space for the other.
  - Clicking a chat sets `activeMainViewProvider` to `MainView.chat`; clicking "Manage Roster" sets it to `MainView.nodeManagement`.
  - Removed the server icon button from the footer controls (no longer needed).

## 3. Centralized Version Theming

- **Modified** `lib/src/theme.dart` — added `ConsciaTheme.versionStyle(context, scale)` which enforces Courier monospace at 10px with the muted color token.
- **Modified** `lib/widgets/modals/account_manager.dart` — replaced the inline `TextStyle(fontFamily: 'Courier', fontSize: 10 * scale, color: ConsciaTheme.muted(context))` with the centralized `ConsciaTheme.versionStyle(context, scale)`.

All future version labels must use this token.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | ✓ 0 errors (3 pre-existing info-level `avoid_print` warnings) |
| `flutter build linux --debug` | ✓ Built `build/linux/x64/debug/bundle/exotalk_flutter` |
