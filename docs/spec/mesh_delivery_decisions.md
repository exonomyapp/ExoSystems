# Mesh Delivery Guarantees — Design Decisions

> This document is written for you, the decision-maker. It explains the three design
> problems we needed to solve for the ExoTalk/Conscia message delivery system —
> what each problem actually is, why it matters, what the realistic options are,
> what trade-offs each option carries, and what we decided. Where a decision
> has meaningful open risk or room for your override, it is flagged explicitly.

---

## Problem 1: How Long Should a Message Wait?

### What This Is About

When you send a message to someone who is offline, Conscia holds it on your behalf.
But "holds it" raises an immediate question: *for how long?*

Think of it like a physical post box. If no one collects the mail, eventually the
postman has to decide: do I keep stuffing letters in forever? Do I return them to
sender? Do I throw them away after six weeks? The answer matters — it affects how
much space the box takes up, what users can rely on, and what operators have to provision.

### Why It Matters

**For users:** If the retention period is too short, a message sent to someone on a
two-week vacation is lost. If it's too long, a message sent to someone who has left
a team and will never reconnect sits on the relay server indefinitely, consuming storage.

**For operators:** Every relay node has a fixed disk budget. A node receiving 1,000
messages per hour and retaining them for 30 days needs to store 720,000 messages
at once. At 10 KB per message, that's 7 GB. At 1 KB, it's 700 MB. Operators running
small personal servers need a sensible cap.

**For the mesh:** If a message expires and is deleted without informing the sender,
the sender thinks the message is still waiting for delivery. That's a lie the system
should not tell silently.

### The Options

**Option A — No expiry.** Hold everything forever.
- Pro: Maximum delivery guarantee.
- Con: Storage grows unboundedly. A small home server will run out of disk.
- Con: Messages to users who have left the mesh stay forever — no cleanup possible.
- **Verdict: Not viable for personal nodes.**

**Option B — Fixed global TTL (e.g., 72 hours, non-configurable).**
- Pro: Simple to understand. No configuration surface.
- Con: A single TTL cannot serve all use cases. A personal Lifeline node might want
  7 days. An enterprise compliance node might need 90 days.
- **Verdict: Too rigid.**

**Option C — Configurable TTL with a default.**
- Pro: Accommodates different use cases without requiring customization for most users.
- Con: Adds configuration complexity. Operators must understand the implications.
- **Verdict: This is what we chose.**

**Option D — User-signaled TTL (sender decides per message).**
- Pro: Fine-grained control.
- Con: The sender cannot know the storage capacity of the recipient's node.
  A sender setting "retain for 365 days" on a node with 500 MB budget is unrealistic.
- **Verdict: Can be a future enhancement layered on top of Option C.**

### What We Decided

- **Default TTL: 72 hours.** This covers the "weekend offline" scenario — the most
  common real-world case for personal Lifeline nodes.
- **Maximum configurable: 30 days.** Enterprise and community relay nodes can extend
  this for compliance use cases.
- **Hard minimum: 1 hour.** This prevents a misconfigured node from silently dropping
  messages that haven't had time to be delivered.
- **Storage cap: 500 MB per node (configurable).** When the cap is hit, the oldest
  events are evicted first (LRU order).
- **On expiry: a signed Tombstone is broadcast.** This is the critical detail. Rather
  than silently discarding the expired message, the node broadcasts a signed record
  saying "this message expired." Two effects: (1) all federated peers can also purge
  it, keeping the mesh consistent; (2) the sender's ExoTalk receives a `delivery_expired`
  notification the next time it connects, so the user knows what happened.

> **Open decision:** The 72-hour default is a judgment call. Signal uses 7 days for
> their sealed sender retry logic. WhatsApp uses 30 days for offline message retention.
> 72 hours is conservative — it errs toward protecting operator storage over guaranteeing
> delivery through long absences. If you want to change this default before v0.8.0,
> now is the time.

---

## Problem 2: What Happens When Your Own Relay Node Is Offline?

### What This Is About

The dev environment federation scenario shows Conscia solving the offline delivery
problem: Exonomy's Conscia holds a message for Exocracy's Conscia to pick up.
But what if *Exocracy's Conscia node is also offline*? What if it crashed, rebooted,
or hasn't been set up yet?

In a pure one-hop model, the message can only travel: `sender → sender's Conscia → recipient's Conscia`. If the recipient has no Conscia at all, or their Conscia is unreachable, delivery fails.

Multi-hop relay asks: can the message travel through *intermediate* nodes — nodes that
are neither the sender's nor the recipient's — to eventually reach its destination?

### Why It Matters

**For the resilience of the resistance:** A federated mesh is only as reliable as its routing. If every message requires both Isabella's client and the Insider's Conscia to be online simultaneously, the system fails the moment the state cuts the fiber. The mesh must route around failures—the same way a guerrilla network routes around a blockade.

**For the community relay use case:** In the Beirut scenario, Isabella and Malik run separate nodes. If Isabella needs to send an urgent war crimes report to a contact whose Conscia is temporarily unreachable due to a power outage, Malik's solar-powered node—if it is in the relay path—could hold the message until the recipient's node comes back online.

**For complexity:** Multi-hop routing is significantly more complex than one-hop.
It introduces routing tables, loop prevention, and the question of *who* is allowed
to relay for *whom*.

### The Options

**Option A — One hop only. No multi-hop.**
- Pro: Maximally simple. Easy to reason about security.
- Con: Delivery fails if the recipient has no running Conscia. Breaks the "always
  delivered" promise for users without personal infrastructure.
- **Verdict: Too brittle for the community relay use case.**

**Option B — Unlimited hops.**
- Pro: Maximum routing flexibility.
- Con: Without a hop limit, a message could loop indefinitely if there are circular
  federation relationships. This is a denial-of-service risk.
- **Verdict: Unsafe without loop prevention. Not viable.**

**Option C — Bounded hops (our choice) with loop prevention.**
- The gossip envelope carries a `ttl_hops` counter (starts at 5, decremented at each
  relay). When it reaches 0, delivery fails cleanly with an error tombstone.
- Loop prevention: each node tracks the last 10,000 event IDs it has seen. If a
  duplicate arrives, it is discarded immediately.
- Pro: Delivers the resilience benefit of multi-hop while bounding the blast radius
  of routing failures.
- **Verdict: This is what we chose.**

**Option D — Source routing (sender specifies the path).**
- The sender includes the explicit relay path in the message envelope.
- Pro: Deterministic. The sender knows exactly how the message will travel.
- Con: The sender must know the topology of the mesh — which nodes exist and which
  are federated with which. This is private infrastructure information the sender
  should not need to know.
- **Verdict: Inappropriate for an independent mesh where topology is not public.**

### What We Decided

- **Maximum hops: 5.** This number is encoded in the gossip envelope and cannot be
  overridden by the sender. It is enough to traverse a reasonably complex federated
  community (sender's node → 3 intermediate relays → recipient's node) while
  preventing runaway routing.
- **Routing strategy: greedy.** Each relay node forwards to *any* peer that has a
  valid Meadowcap delegation path to the destination namespace. No global routing
  table is maintained — routing is emergent from the delegation graph.
- **Failure handling:** When `ttl_hops` hits 0, a `delivery_unreachable` tombstone
  is sent back along the relay path. The originating ExoTalk surfaces this as
  "Could not reach recipient — retrying in N minutes."
- **Retry: exponential backoff.** 5 min → 15 min → 1 hr → 6 hr → 24 hr. If the
  target Conscia comes back online within the message's TTL, an intermediate relay
  node that holds the buffered event re-attempts direct delivery.

> **Open decision:** The choice of 5 as the hop limit is somewhat arbitrary.
> 3 might be sufficient for most realistic topologies. 10 would allow very complex
> federated networks but increases the attack surface for routing abuse. Does 5
> feel right for the community we envision?

> **Open decision:** The greedy routing strategy means messages may take sub-optimal
> paths. A future enhancement could add a lightweight routing hint in the federation
> handshake (e.g., "I have a delegation path to namespace X") to allow smarter
> forwarding without full topology disclosure.

---

## Problem 3: When Does "Delivered" Actually Mean Delivered?

### What This Is About

This is the most nuanced of the three problems because it sits at the intersection
of technology and human expectation. When you send a message and see a checkmark,
what does that checkmark mean?

There is no universally correct answer. Different messaging systems make different
choices, and each choice carries a different privacy trade-off.

There is no universally correct answer. Different messaging systems make different choices, and each choice carries a different risk in a surveillance state.

Let's make this concrete with a scenario:

> Isabella sends a war crimes report to Malik. Malik's Conscia node receives it at 9:00 AM while Malik is in a deep-cover meeting. Malik's phone is off. At 11:00 AM, Malik turns his phone on and ExoTalk downloads the message. At 2:00 PM, Malik opens the conversation and reads the report.

From Isabella's perspective, three distinct things happened at 9:00, 11:00, and 2:00 PM. The question is: which of these should Isabella know about? And more importantly, what metadata is Malik leaking to the **Palantir** algorithms monitoring the network?

### The Delivery State Options

The key insight is that there are **four distinct moments** in the lifecycle of
a message in the Conscia mesh:

| Moment | Who acts | What happened |
|---|---|---|
| ① **Sent** | Isabella's ExoTalk | Message submitted to Isabella's Conscia |
| ② **Node Received** | Malik's Conscia | Malik's relay accepted and stored the message |
| ③ **Client Received** | Malik's ExoTalk | Malik's app downloaded and decrypted the message |
| ④ **Read** | Malik (the human) | Malik opened the conversation and saw the message |

In a pure P2P world (no Conscia), states ② and ③ collapse into one. Conscia introduces ② as a distinct intermediate state—and in a high-stakes environment, that distinction is the difference between "I sent it" and "The network has it."

### Why Privacy Is the Central Tension

**State ②** (Node Received) is benign from a security perspective. It tells Isabella that the infrastructure received her message. It does not reveal Malik's physical state—he might be in transit, in a bunker, or maintaining radio silence.

**State ③** (Client Received) starts to reveal something dangerous: Malik's device is online and his ExoTalk is running. In conflict zones, this pattern of "online/offline" is exactly what **Palantir**’s Gotham platform uses to identify the habits of human rights defenders.

**State ④** (Read) reveals that Malik actively opened the conversation. This is the most privacy-sensitive state. It confirms not just that Malik is online, but that Malik chose to look at Isabella's message—and possibly chose not to respond.

### The Options

**Option A — No receipts at all. Fire and forget.**
- Users only ever see ① (Sent). No delivery confirmation.
- Pro: Maximum privacy for the recipient.
- Con: Senders have no confidence that messages were received. Urgent messages become
  anxiety-inducing — did it go through?
- **Verdict: Too austere. Breaks user trust in the system.**

**Option B — ② only (Node Received).**
- Senders see: "the relay node got it." Nothing more.
- Pro: Confirms infrastructure delivery without revealing human behavior.
- Con: Leaves senders uncertain whether the *person* has the message.
- **Verdict: Reasonable default. This is what Email effectively does.**

**Option C — ② + ③ always on (Client Received, automatic).**
- Senders always know when Malik's device downloaded the message.
- Pro: Stronger delivery confirmation.
- Con: Malik loses control over his operational security. This is the WhatsApp model—unacceptable for an autonomy-first platform.
- **Verdict: Too invasive as a default.**

**Option D — ② + ③ + ④ always on (full read receipts, automatic).**
- Maximum sender confirmation, minimum recipient privacy.
- Pro: Unambiguous delivery semantics.
- Con: This is essentially surveillance. Recipients cannot choose whether to reveal
  that they have read a message.
- **Verdict: Not appropriate for an autonomy-focused platform.**

**Option E — ② always on; ③ and ④ opt-in per conversation (our choice).**
- By default, only Node Received is reported. Recipients can choose to share Client
  Received and Read for specific conversations.
- Pro: Respects recipient autonomy. Matches Signal's model.
- Pro: The sender always knows infrastructure delivery succeeded — they are not
  left in complete uncertainty.
- Con: "Opt-in" requires a UI surface in the privacy settings and per-conversation
  toggles — this is implementation work.
- **Verdict: This is what we chose.**

### What We Decided

- **States ① and ② are always reported** to the sender. The sender knows they sent
  the message, and knows the relay node received it. This is the minimum information
  needed for a functional messaging system.
- **States ③ and ④ are opt-in per conversation.** Disabled by default. Malik enables them only in high-trust conversations.
- **The UI follows Signal's tick metaphor:** single tick ✓ (Sent) → grey double ✓✓ (Node Received) → coloured double ✓✓ (Client Received) → accent-coloured ✓✓ (Read). 
- **Ack events use the same mesh.** If Isabella is offline when Malik's ack fires, she will receive it when she reconnects.

### One Important Subtlety: State ② in Pure P2P Sessions

In a pure P2P conversation (no Conscia, both users online simultaneously), state ②
does not exist as a distinct event — the message lands directly in the recipient's
ExoTalk, collapsing ② and ③ into a single moment. The UI should handle both cases:
- **With Conscia:** ① → ② (grey ✓✓) → ③ (coloured ✓✓) → ④ (accent ✓✓)
- **Without Conscia:** ① → ③ (coloured ✓✓) — skipping ②
- This is a detail the implementation must handle correctly; the user should never
  see an inconsistent tick state.

> **Open decision:** The opt-in model for ③ and ④ requires a UI surface. We need to
> decide: is this a global setting ("I never share read receipts") or per-conversation
> ("I share read receipts with Isabella but not with the Insider")? We chose per-conversation
> in the spec.

---

## Summary: Your Decisions to Confirm

| Topic | What We Decided | Open for Your Input |
|---|---|---|
| Default TTL | 72 hours | Should this be 7 days? 24 hours? |
| Max configurable TTL | 30 days | Is 30 days sufficient for enterprise? |
| Max hop count | 5 | Is 3 enough? Too few? |
| Read receipts default | States ① ② only | Agree with opt-in model? |
| Read receipt granularity | Per-conversation toggle | Should there be a global off-switch too? |

The formal specification with configuration schemas and implementation priority is in
[spec/16_mesh_delivery_guarantees.md](../spec/16_mesh_delivery_guarantees.md).
