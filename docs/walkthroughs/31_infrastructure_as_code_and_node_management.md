# Walkthrough 31: Infrastructure as Code & Node Management Dashboard

This walkthrough documents our transition to a declarative infrastructure model for Conscia nodes and the integration of a unified Node Management Dashboard within the ExoTalk client.

## 1. Documentation Modernization
We updated the `docs/conscia_ops_guide.md` to reflect our recent architectural shifts:
- Eradicated legacy manual execution (`nohup`) and brittle process termination (`pkill`) examples.
- Standardized all remote administration commands to use `systemctl` (e.g., `sudo systemctl start conscia` and `journalctl -u conscia -f`), ensuring operational instructions match our Systemd reality.

## 2. Infrastructure-as-Code (Terraform)
To support reliable and uniform deployment of Conscia nodes across diverse targets, we replaced the monolithic, bash-driven GCP script with declarative Terraform configuration:
- **Deprecation**: Removed `infra/gcp_push.sh`.
- **Terraform Integration**: Created `infra/terraform/main.tf` and `infra/terraform/variables.tf`.
- **Naming Convention**: Strictly enforced the `conscia` package and resource naming convention across the infrastructure logic, completely removing any reference to the outdated `conscia-node` suffix.
- **Null Resource Strategy**: The initial `main.tf` employs a `null_resource` with `local-exec` provisioners to seamlessly wrap our existing SSH orchestration (`mkdir`, `scp`, `systemctl restart`) into Terraform's declarative state model, triggered by binary hash changes.

## 3. Node Management Dashboard
We centralized operational control of federated nodes directly into the ExoTalk user interface.
- **New UI Component**: Implemented `NodeManagementDashboardModal` inside `exotalk_flutter/lib/widgets/modals/node_management_modal.dart`.
- **Solid Identity Aesthetic**: The modal was built using our established aesthetic (omitting glassmorphism), featuring a clean "Federation Status" overview and an "Active Roster" list.
- **Integration**: Added a new server icon button `LucideIcons.server` to the `_SidebarBottomControls` in the ExoTalk `home_screen.dart` footer to launch the dashboard.
- **Capabilities**: The dashboard lays the groundwork for monitoring node health (via `consciaStatusProvider`) and provides the interactive stubs for Meadowcap capability revocation and remote node restarts.

## How to Verify
1. **Documentation**: Open `docs/conscia_ops_guide.md` and review the "Remote Administration" section to confirm only `systemctl` commands are present.
2. **Infrastructure**: Navigate to `infra/terraform/` and inspect `main.tf` and `variables.tf`.
3. **Application**: Run `cd exotalk_flutter && flutter run -d linux`. Look at the bottom left of the sidebar, next to the Settings gear icon, and click the new Server icon to open the Node Management Dashboard.

## Final Build Verification
- All code successfully compiles for Linux (`flutter build linux --debug`).
- The codebase passes strict static analysis (`flutter analyze` exited with 0 issues in the new file).
