# Specification 23: Exonomy Topology

## 1. Overview
Exonomy is a completely distinct, standalone **social media platform** within the Sovereign Exosystem. 

Unlike traditional platforms that rely on hollow "likes" (e.g., for pictures of cappuccino art or cat trick videos), Exonomy uses **vouchers as economic instigators**. The "Exonomist" creates and exchanges these vouchers, and can optionally buy or sell them for real-world fiat currency. 

While Exonomy naturally interoperates with higher-level apps (for instance, its vouchers *can* be used to fund tasks in Exocracy), it operates entirely independently by default. It is not merely a stepping stone; it is a fully realized ecosystem of structured value exchange.

## 2. Triad Distribution Matrix

To handle the complexity of voucher content management without sacrificing sovereign custody, Exonomy is distributed across the Application Triad:

| Tier | Component | Primary Role |
| :--- | :--- | :--- |
| **Mobile (`_lite`)** | `exonomy_lite` | Mobile-first Flutter app for rapid voucher claiming, peer-to-peer value exchange, and on-the-go milestone approvals. |
| **Desktop (`_flutter`)** | `exonomy_flutter` | Heavy UI Flutter client for Exonomists managing complex voucher ledgers, tracking value exchange histories, and performing extensive cryptographic auditing. |
| **Indexing Node (`_web`)** | `exonomy_web` | High-throughput Rust indexing service providing a public/private search fabric for available vouchers and bounties, managed via a Flutter Web dashboard. |

## 3. The Indexing Relay
The `exonomy_web` node acts as a "Consciosophical" facilitator. It hosts encrypted voucher payloads blindly, only indexing the explicitly decorated metadata (e.g., bounty amount, skill requirements, geographic tags) published by the Exonomist. This allows global crowdsourcing of tasks without exposing the underlying cryptographically sealed proof-of-work.
