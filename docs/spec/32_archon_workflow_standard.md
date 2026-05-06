# 32. Archon Workflow Standard

This specification governs the use of **Archon** as the tactical execution engine within the Sovereign Exosystem. Archon translates high-level architectural plans into deterministic actions.

## 1. YAML DAG Principles

All autonomous coding tasks must be defined as Directed Acyclic Graphs (DAGs) in YAML format.

*   **Idempotency**: Every Archon step must be safe to execute multiple times without causing corrupt state.
*   **Strict Verification**: No Archon DAG may terminate successfully without a validation step. For backend code, this means `cargo test`. For UI code, this enforces the **KDVV (Keystroke-Driven, Visual-Verified)** protocol via `xdotool` and `scrot` execution within the DAG.
*   **Telemetry Hooking**: Every Archon workflow must instantiate an OpenTelemetry (OTel) span to broadcast its progress to the Arize Phoenix container hosted on Exonomy.

## 2. Granularity and Scope

Archon is designed for tactical execution, not grand strategy.
*   A DAG should encompass a single logical PR (e.g., "Implement ExoTheme Toggle Button").
*   If a DAG exceeds 10 discrete steps, it must be broken down and fed back to the Core Architect for modularization.

## 3. GitHub Projects Integration

Archon workflows are deeply tied to the Cockpit and GitHub Projects.
*   When an Archon DAG begins, it uses the `gh` CLI to move its corresponding GitHub Issue to the `In Progress (Agent)` column.
*   If a DAG encounters an unrecoverable compilation error after 3 self-correction loops, it halts, moves the issue to `Blocked (Needs Human)`, and tags the human orchestrator.
*   Upon successful completion and Promptfoo validation, the DAG pushes the branch, opens a PR, and tags the *Documentation Expert* for the final hygiene pass.
