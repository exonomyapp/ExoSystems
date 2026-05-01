# Improvement Notes

This file tracks potential UI/UX and architectural improvements identified during development sessions. These are deferred tasks to prevent scope creep.

## UI/UX Improvements
- **Animated Transition for Technical Footer**: Add a slide-in or fade-in animation when the sidebar expands to reveal the technical footer.
- **Sparkline for Traffic Pulse**: Instead of raw numbers, add a 10-second history sparkline for Ingress/Egress in the footer.
- **Copy-to-Clipboard for All Telemetry**: Allow clicking on any footer item (Node ID, IP) to copy the raw value.

## Architectural Improvements
- **Telemetry Authentication**: Add a simple API key requirement for the Telemetry API (even on loopback) for production hardening.
- **Plugin System for Telemetry**: Allow apps to register custom telemetry providers (e.g., Exonomy might want to show minted voucher count).
- **Persistent Telemetry Logs**: Stream telemetry logs to a circular buffer on disk for post-mortem analysis of failed mesh handshakes.
