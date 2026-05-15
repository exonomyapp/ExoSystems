# Walkthrough 12: The SvelteKit Migration

This document records the replacement of React/Next.js with Svelte/SvelteKit for desktop applications in the Exosystem.

## Rationale for SvelteKit

During the expansion of the Exosystem (Exonomy, Exocracy), the frontend technology stack was re-evaluated.

### Technical Limitations of React
React utilizes a Virtual DOM engine that diffs the virtual tree against the real DOM on state changes. This process increases memory and CPU usage.

### Svelte Benefits
Svelte compiles components at build time into vanilla JavaScript that updates the DOM directly. This removes the need for a framework runtime in the browser, reducing overhead.

This approach aligns with the resource-efficient design of the Rust backend.

## Migration Process

Because the Rust backend (`republet_desktop`) is decoupled from the frontend UI, replacing the frontend framework did not require modifications to the Rust code.

The migration involved:
1. Deleting the `republet_web/` Next.js directory.
2. Initializing a new SvelteKit, Vite, and TypeScript project.
3. Reconfiguring the `src-tauri` symlink to point to `../exotalk_engine/republet_desktop`.

The decoupled architecture allowed for a frontend replacement without modifications to the Rust backend.

## Platform Matrix

The Exosystem utilizes a dual-framework strategy:

| Technology | Used For | Rationale |
|---|---|---|
| **Flutter** | ExoTalk, Exonomy, RepubLet Lite, Exocracy Lite | Cross-platform mobile and desktop deployment from a single codebase for social and feed interfaces. |
| **SvelteKit + Tauri** | RepubLet Web, Exocracy Web | Document editing and data visualization utilizing the JavaScript library ecosystem (ProseMirror, D3.js). |

## Performance Metrics

| Metric | Next.js | SvelteKit |
|---|---|---|
| `npm install` packages | ~300+ | 48 |
| Framework runtime shipped to user | ~80KB+ (React) | 0 (Compiled) |
