# Walkthrough 71: Root Documentation Restoration

The monorepo root and documentation have been consolidated to reflect the project identity.

## Milestones

### 1. Root Documentation Restoration
- **Archival**: Relocated legacy `zrok` files (`README.md`, `CHANGELOG.md`, `LICENSE`, `zrok.tar.gz`) to `docs/archive/zrok/`.
- **Root Documentation**: Established the new `README.md` as the entry point for the Application Triad.
- **License Update**: Updated the root `LICENSE` to **AGPL-3.0**.
- **Changelog**: Redefined `CHANGELOG.md` as a reference to the walkthrough system.

### 2. Navigation Links
- Implemented navigation links across major READMEs and specifications to ensure consistent navigation.
- Updated directory links in the root README to reference `README.md` files directly.

### 3. Specification Consolidation
- **Information Retrieval**: Extracted identity onboarding, terminal UI protocol, and developer distribution details from legacy files.
- **Integration**: Re-homed extracted details into:
    - `docs/spec/07_ui_functionality.md` (TUI Strategy).
    - `docs/spec/17_front_door_standard.md` (Onboarding).
    - `docs/spec/20_distribution_control_panel.md` (NPM Lifecycle).
    - `docs/spec/23_exonomy_topology.md` (Deployment Levels).
- **Purge**: Removed the `docs/spec/legacy/` directory and updated the Specifications Index.

## Verification Results
- **Link Audit**: Verified relative path accuracy for navigation links and sub-project references.
- **Visual Audit**: Repository logo centered and resized for optimal display.
- **Git State**: All changes committed to the master branch.

---
**Status**: Root documentation restored. Monorepo sanitized.
