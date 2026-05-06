# Walkthrough 12: The SvelteKit Migration

*This document records the replacement of React/Next.js with Svelte/SvelteKit for all heavyweight desktop applications in the Sovereign Exosystem.*

## 🧹 Why We Left React Behind

When RepubLet was first scaffolded (Walkthrough 10), we used Next.js as the desktop frontend framework. However, as the Exosystem expanded (Exonomy, Exocracy), we re-evaluated the frontend technology stack.

### The Problem with React
React ships a massive Virtual DOM engine to the user's browser. On every state change, React diffs the entire virtual tree against the real DOM to figure out what changed. This is computationally expensive, memory-heavy, and philosophically misaligned with our Rust-first, zero-overhead architecture.

### Why Svelte Wins
Svelte takes a radically different approach: **it compiles away at build time.** Instead of shipping a framework to the browser, the Svelte compiler analyzes your components and outputs tiny, surgically precise vanilla JavaScript that updates the DOM directly. No virtual DOM. No diffing. No framework overhead.

This "compile to nothing" philosophy perfectly mirrors Rust's own zero-cost abstraction principle.

## 🔧 The Surgical Swap

Because we had already fully decoupled the Rust backend (`republet_desktop`) from the frontend UI (Walkthrough 10 & 11), replacing the entire frontend framework required **zero changes to any Rust code**.

The operation was:
1. Delete the entire `republet_web/` Next.js directory.
2. Scaffold a new SvelteKit + Vite + TypeScript project in its place.
3. Recreate the `src-tauri` symlink pointing back to `../exotalk_engine/republet_desktop`.

The Rust engine didn't even notice the swap happened. This is the ultimate vindication of the decoupled architecture.

## 📐 The Platform Matrix

With SvelteKit established, the Exosystem now follows a clear technology split:

| Technology | Used For | Why |
|---|---|---|
| **Flutter** | ExoTalk, Exonomy, RepubLet Lite, Exocracy Lite | Standardized social/feed UIs that need cross-platform mobile + desktop from one codebase |
| **SvelteKit + Tauri** | RepubLet Web, Exocracy Web | Complex document editing and data visualization that benefit from the mature JS library ecosystem (ProseMirror, D3.js, Gantt libraries) |

## 🧮 The Numbers

| Metric | Next.js | SvelteKit |
|---|---|---|
| `npm install` packages | ~300+ | 48 |
| Vulnerabilities | Variable | 0 |
| Framework shipped to user | ~80KB+ (React runtime) | 0 (compiled away) |
