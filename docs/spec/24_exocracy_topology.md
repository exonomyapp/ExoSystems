# Exocracy Distribution & User Experience Specification

This document defines the distribution strategy for Exocracy, the decentralized project management and voucher-based funding platform.

## 1. Philosophical Identity & Independence
Exocracy is the "Governance Layer" of the mesh. It is a completely independent application designed for high-trust environments where organizational transparency and independent project management are paramount.

**Modular Funding**: Exocracy can operate entirely without vouchers, accepting real-world forms of money as project funding. However, in the spirit of the Exosystem's open architecture, an Exocracy project manager can *optionally* modularize their workflow by choosing to fund tasks using **Exonomy vouchers**. This is an engineered interoperability feature, not a rigid app-level dependency.

## 2. Platform Distribution Matrix

| Tier | Component | Primary Role |
| :--- | :--- | :--- |
| **Mobile (`_lite`)** | `exocracy_lite` | Mobile-first Flutter app for real-time voting, task tracking, and lightweight project notifications. |
| **Desktop (`_flutter`)** | `exocracy_flutter` | Heavy UI Flutter client for project managers requiring complex layouts (Gantt charts, deep organizational views, voucher milestone mapping). |
| **Indexing Node (`_web`)** | `exocracy_web` | High-throughput Rust indexing service providing public/private search indexing for open tasks and bounties, managed via a Flutter Web dashboard. |

## 3. Related Documents
- [Distribution & Acquisition Strategy](21_distribution_and_acquisition_strategy.md)
- [Conscia Management](conscia_manage.md)
