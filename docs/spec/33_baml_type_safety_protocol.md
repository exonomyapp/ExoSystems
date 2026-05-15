# 33. BAML Type Safety Protocol

This specification outlines the integration of **BoundaryML (BAML)** as the foundational reliability layer for all LLM interactions within the Exosystem SDLC.

## 1. The Reliability Mandate

Agentic coding frameworks frequently fail due to silent hallucination or malformed JSON outputs. In the Exosystem, no agent is permitted to make raw strings-to-strings LLM calls for structured data. All structured output must be mediated by BAML.

## 2. BAML Schema Definition

*   **Typed Prompts**: All prompts are defined as strongly-typed functions with explicit input and output schemas.
*   **Compilation**: BAML schemas are compiled into native SDKs (e.g., Python or TypeScript) which the Archon DAGs and BMAD scripts import natively.
*   **Fail-Safe Serialization**: BAML handles serialization errors gracefully, ensuring that if an LLM returns extraneous markdown around a JSON block, the SDK parses it correctly without crashing the execution pipeline.

## 3. The QA Auditor's Role

The **QA Auditor** persona is responsible for maintaining the BAML schema directory.
*   Whenever a new agentic tool is required, the Architect defines the BAML schema.
*   The QA Auditor enforces rigorous regression testing using `baml-cli test`.
*   Before any Promptfoo evaluation runs, the underlying BAML schemas must compile and pass deterministic validation to ensure "Test Before Deliver" compliance at the prompt level.
