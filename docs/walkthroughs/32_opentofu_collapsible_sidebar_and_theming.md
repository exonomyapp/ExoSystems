# Walkthrough 32: OpenTofu Migration, Collapsible Sidebar & Centralized Theming

This walkthrough documents three architectural refinements: adopting OpenTofu as the IaC tool, replacing the node management modal with a native sidebar-integrated view, and centralizing version theming.

## 1. Infrastructure: Terraform → OpenTofu

OpenTofu was evaluated against Terraform and Pulumi for provisioning Conscia servers:

- **Pulumi** was excluded to avoid introducing additional programming languages (TypeScript/Go) into the Dart/Rust monorepo.
- **Terraform** was excluded due to the BSL license change, which is not compatible with project requirements.
- **OpenTofu** was selected for its compatibility with the existing provider ecosystem (GCP, AWS), use of declarative HCL, and open governance.

**Change:** Renamed `infra/terraform/` to `infra/opentofu/`. The `main.tf` and `variables.tf` files remain unchanged in content; the directory name reflects the migration to OpenTofu.

## 2. Node Management: Modal → Sidebar-Integrated View

Node management has been moved from a modal to a native sidebar and main content area view.

### Changes Made
- **Deleted** `lib/widgets/modals/node_management_modal.dart`.
- **Created** `lib/screens/node_management_view.dart`: A full-screen view rendered in the main content area when a Conscia node is selected.
- **Modified** `lib/screens/home_screen.dart`:
  - Added `MainView` enum and `activeMainViewProvider` to track whether the user is viewing a Chat or the Node Management screen.
  - Replaced the `_ConversationList` with `_SidebarContent`, containing two collapsible `ExpansionTile` groups:
    1. **Chats**: The conversation list.
    2. **Conscia Nodes**: The node roster.
  - Clicking a chat sets `activeMainViewProvider` to `MainView.chat`; selecting a node sets it to `MainView.nodeManagement`.
  - Removed the server icon button from the footer controls.

## 3. Centralized Version Theming

- **Modified** `lib/src/theme.dart`: Added `ConsciaTheme.versionStyle(context, scale)` to standardize Courier monospace at 10px with the muted color token.
- **Modified** `lib/widgets/modals/account_manager.dart`: Replaced inline styling with the centralized `ConsciaTheme.versionStyle` token.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors |
| `flutter build linux --debug` | Successful build of `exotalk_flutter` |
