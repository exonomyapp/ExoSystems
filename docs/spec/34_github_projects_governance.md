# 34. GitHub Projects Governance & The Agentic SDLC Cockpit

This specification defines the Human-in-the-Loop interface for managing our Event-Driven Multi-Agent SDLC.

## 1. The Cockpit Dashboard

Because native GitHub Projects does not visually differentiate between human states and complex AI states, we employ a custom **Flutter Web Dashboard** known as the **"Agentic SDLC Cockpit."**

*   The Agentic SDLC Cockpit interfaces securely with GitHub via the GraphQL API (using the `gh` CLI credentials).
*   It provides a real-time, unified view of all Agent Personas, showing exactly which GitHub Issue they are currently "thinking" about, tracing, or commenting on.

## 2. Issue Lifecycle and Automation

All tasks are driven through GitHub Issues with strict state definitions:

1.  **Todo**: Backlog, awaiting the Lead PM to scope into a PRD.
2.  **In Progress (Agent)**: An Archon DAG or BMAD phase is actively executing. Human intervention is not required.
3.  **Blocked (Needs Human)**: The agent has encountered a failure it cannot self-correct, or the Architect requires human sign-off on a major topological change.
4.  **Review (Doc Expert)**: Code is complete; the Documentation Expert is enforcing hygiene and generating READMEs.
5.  **Done**: Merged and verified.

## 3. Webhook Event Routing

The Agentic SDLC Cockpit acts as the central router for GitHub Webhooks.
*   When an event occurs (`issue_created`, `issue_comment`), the Cockpit parses the payload and determines which SME Observers (e.g., *P2P Scientist*, *Conscia Strategist*) should be awakened to inject asynchronous expertise.
*   **On-Demand Brainstorming**: If the Cockpit detects an `@mention` targeting an agent persona in a comment, it spawns a dedicated sub-process for that agent to parse the thread and respond immediately.
