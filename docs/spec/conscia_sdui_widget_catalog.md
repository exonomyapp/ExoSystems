# Conscia SDUI Widget Catalog

## Overview

Conscia nodes advertise a list of available SDUI (Server-Driven UI) widget identifiers via `GET /api/capabilities`. Client applications use these identifiers to dynamically render UI components appropriate to the services offered by the connected node.

This catalog serves as the living registry of all known widget identifiers, their originating application domain, the Conscia service they represent, and the expected rendering behavior in a consuming client.

> This document evolves as the Exosystem expands. New applications register new widget identifiers by defining them here and implementing the corresponding Conscia service.

---

## Widget Registry

| SDUI Widget ID | Application Domain | Conscia Service | Client Rendering |
|---|---|---|---|
| `FederationTopology` | Conscia (core) | Federation graph | Read-only graph of peered Conscia nodes with geographic and latency context |
| `AuthStatus` | Conscia (core) | Capability governance | Current petition status and granted permission level for the connected DID |
| `MetadataSearch` | All apps | Blind metadata indexing | Full-text search interface across public metadata tags |
| `CircleDirectory` | ThreeSteps | Circle metadata indexing | List of circles with type, description, and petition-to-join action |
| `ForumBrowser` | ThreeSteps | Forum hosting | Browsable forum listing with highlighted circles |
| `ChatGroupIndex` | ExoTalk | Group relay metadata | Directory of active chat groups with membership status |
| `VoucherMarketIndex` | Exonomy | Localized voucher market indexing | Voucher listings organized by region, type, and availability |
| `ProjectDirectory` | Exocracy | Cross-node project federation | Directory of federated social projects with participation actions |
| `DatasetCatalog` | RepubLet | Cold storage pinned inventory | Pinned dataset browser with author, tags, and size metadata |

---

## How SDUI Works

1. Client calls `GET /api/capabilities` on a Conscia node.
2. The response includes a `sdui_widgets` array of string identifiers.
3. The client maps each identifier to a local Flutter widget.
4. If a widget identifier is unknown to the client, it is silently ignored (forward-compatibility).
5. If the Conscia node does not advertise a widget, the client does not render it.

This model ensures:
- **Client independence**: no hardcoded assumptions about what a node offers
- **Node autonomy**: operators control which services they expose
- **Forward-compatibility**: new widgets can be added to Conscia without updating all clients simultaneously

---

## Related Documents

- [Spec 19: Verification & Telemetry API](./19_verification_telemetry_api.md) — API endpoint reference
- [Spec 38: Conscia Federation & Service Architecture](./38_conscia_federation_and_services.md) — service catalog and federation model
- [Spec 22: Application Triad Architecture](./22_application_triad_architecture.md) — the Triad model that consuming clients follow
