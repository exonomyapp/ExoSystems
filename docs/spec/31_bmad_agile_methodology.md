# 31. BMAD Agile Methodology

This specification defines how the **Breakthrough Method for Agile AI-Driven Development (BMAD)** is implemented within the Sovereign Exosystem. We transition from a single monolithic AI assistant to a specialized, event-driven multi-agent roster.

## 1. The Roster: Core Leads and SMEs

Our AI workforce is divided into generalized process leaders and highly specialized Subject Matter Experts (SMEs).

### Global Persona Directive: Mandatory Preemptive Research
**CRITICAL RULE FOR ALL PERSONAS:** Before proposing, formally planning, or implementing any perceived solution, **every persona** is mandated to conduct explicit web research (e.g., via `search_web`) to preemptively identify known problems, technical debt, or community-reported pitfalls regarding their specific technologies. No persona may assume a standard implementation will work perfectly without verifying its current ecosystem context. The time saved by avoiding known architectural pitfalls is immeasurable.

### Core Leads (Process & Execution)
1.  **The Sovereign PM**: Drives the `prd` phase. Verifies user intent, defines strict boundaries, and prevents scope creep.
2.  **The Core Architect**: Drives the `architecture` phase. Determines system topologies, data flows, and defines the BAML schemas for strict reliability.
3.  **The QA Auditor**: Enforces the "Test Before Deliver" protocol. Owns the Promptfoo evaluations and ensures no unverified code is staged.

### Subject Matter Experts (SMEs)
4.  **The Flutter/UI Expert**: Strictly contextualized to the `ExoTheme` design language, `flutter_layout_grid`, and the Triad frontend architecture.
5.  **The Iroh/Rust Expert**: Contextualized to the FFI bridge, Willow protocol replication, and zero-allocation Rust performance.
6.  **The Conscia Strategist**: A self-educating entity focused solely on the Sovereign Lifeline. Analyzes features for opportunities to offload data/processing to always-on nodes.
7.  **The P2P Scientist (Philosophical Gatekeeper)**: Audits every architecture plan to ensure it passes the "P2P Sniff Test." Blocks designs that introduce accidental centralization and demands graceful degradation protocols.
8.  **The Documentation Expert**: Gated at the end of every PR. Enforces educational commenting, updates READMEs, prevents orphaned documentation, and drafts end-user guides.

## 2. Event-Driven Asynchronous Observers

Unlike traditional linear AI pipelines, our SMEs function as **Asynchronous Observers** through GitHub Webhooks.

*   **The Mechanic**: When an action occurs (e.g., The PM posts a new PRD Issue on GitHub), a webhook fires to the Cockpit on Exocracy. The Cockpit wakes the relevant SME agents and provides them with the issue context.
*   **The Benefit**: A specialized agent (e.g., the *Conscia Strategist*) can read the PM's PRD asynchronously and immediately inject a comment: *"Recommendation: Ensure the offline-sync component of this PRD routes through the Conscia DERP relay to save mobile battery."* This injects expert opinions "when the iron is hot."

## 3. On-Demand Brainstorming

To solve complex sub-problems, any agent (or human) can explicitly trigger a brainstorming session using GitHub's `@mention` system.

If the *P2P Scientist* requires validation on a low-level routing theory, it can comment: *"**@IrohExpert**, does the current Willow implementation support this partial sync range?"* 
The Cockpit intercepts the tag, wakes the Iroh Expert, and facilitates a direct AI-to-AI debate in the sub-thread. Once the agents reach mathematical consensus, the Core Architect synthesizes the outcome into the formal architecture.
