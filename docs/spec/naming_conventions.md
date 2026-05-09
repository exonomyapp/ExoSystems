# Specification: Naming Conventions

This document defines the naming conventions for assets within the Sovereign Exosystem documentation and production pipeline.

## 1. Scenario Asset Ordering

To ensure that assets related to a specific scenario (e.g., `00_solid_front_door`) appear in a logical order when sorted alphabetically, we use a numeric-prefixed suffix scheme. The base identifier (the episode/scenario name) remains at the start of the filename.

The sequence always begins with the foundational documents:
1.  **Scenario Document** (`.01.scenario.md`)
2.  **Screenplay Document** (`.02.screenplay.md`)

Subsequent assets (Videos, Audios, Images) are numbered sequentially (**03, 04, 05...**) based on the **Introduction-Order Rule** described below.

When sorted alphabetically, this ensures that the file list mirrors the narrative progression of the production pipeline.

## 2. Type-Agnostic Asset Numbering

For assets (videos, audios, images) that are referenced within both the Scenario and the Screenplay, we follow a narrative-driven numbering rule:

1.  **Introduction Order**: Assets are numbered sequentially based on the order in which they are first introduced in the combined narrative (Scenario + Screenplay).
2.  **Type Agnostic**: The sequence number is assigned regardless of whether the asset is a video, audio, or image.
3.  **Informative Indexing**: This numbering is reflected in the numeric prefix of the suffix (e.g., `.03`, `.04`).

## 3. Infrastructure & URLs

To ensure cross-reboot stability and professional branding, all public-facing sovereign infrastructure must follow the **Stable Service Token** standard.

### 3.1. Public zrok Shares
All public URLs must be **reserved** using the `zrok reserve` command to prevent ephemeral token rotation.

*   **Format**: `<service><nodename>`
*   **Rules**: 
    *   Strictly **lowercase alphanumeric** (a-z, 0-9).
    *   No dots, hyphens, or underscores (as per stable zrok v1 requirements).
*   **Examples**:
    *   Relay: `exotalkberlin` (for `exotalkberlin.share.zrok.io`)
    *   Conscia: `conscianikolasee` (for `conscianikolasee.share.zrok.io`)

This naming convention prioritizes service identity at the front, followed by the node's geographic or functional name, ensuring that clusters of nodes are grouped naturally in account lists.
