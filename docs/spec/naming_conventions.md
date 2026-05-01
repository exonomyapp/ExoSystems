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

This approach ensures that the file list reflects the "drama" or "story" progression, providing more context to the agent and human reviewers about when each asset is deployed in the production workflow.
