# Spec 27: Storage Infrastructure Matrix

Comparative analysis of S3-compatible and P2P storage solutions for the Conscia-verse ecosystem.

## 🔧 Self-Hosted S3-Compatible

- **MinIO**
  - License: AGPL-3.0 (Feb 2026); binaries discontinued; self-compile/commercial required
  - S3 API: ✅ Full (v4 auth, multipart, lifecycle)
  - P2P: ❌ Centralized only
  - Scale: 1 node → 1000+ nodes; erasure coding
  - Complexity: Low-Medium
  - Perf: High throughput
  - Best: Existing MinIO users; teams comfortable with AGPL/commercial terms

- **SeaweedFS**
  - License: Apache 2.0 ✅
  - S3 API: ✅ Full compatibility layer
  - P2P: ❌ (but supports geo-replication)
  - Scale: Horizontal; master/volume architecture
  - Complexity: Medium
  - Perf: Optimized for small files (O(1) lookup)
  - Best: High I/O, small-file workloads; license-sensitive deployments

- **Garage**
  - License: AGPL-3.0
  - S3 API: ✅ Core operations (PUT/GET/LIST)
  - P2P: ⚠️ Geo-distributed design (not true P2P)
  - Scale: Designed for 3-50 nodes; lightweight consensus (Raft)
  - Complexity: Low (single Rust binary)
  - Best: Edge deployments, homelabs, backup targets

- **Ceph (RADOS Gateway)**
  - License: LGPL-2.1
  - S3 API: ✅ Via RadosGW
  - P2P: ❌ Centralized cluster
  - Scale: Massive (PB+)
  - Complexity: High (Tuning required)
  - Best: Enterprise on-prem; large-scale ops teams

## 🌐 P2P / Decentralized

- **Storj**
  - License: AGPL-3.0 (satellite/uplink)
  - S3 API: ✅ Native, production-ready gateway
  - P2P: ✅ True decentralized storage network
  - Scale: Global node network
  - Complexity: Low (managed satellite)
  - Best: Backups, archives, media; S3 drop-in with decentralization

- **Filecoin + IPFS**
  - License: Apache 2.0 / MIT
  - S3 API: ❌ Native; ✅ via gateways
  - P2P: ✅ Full IPFS content-addressed P2P
  - Scale: Global DHT
  - Complexity: High
  - Best: Web3 apps, public datasets, immutable archives

## ⚡ Key Differentiators

- **License safety**: SeaweedFS, RustFS, Rook = Apache 2.0
- **Smallest footprint**: Garage (~10MB binary)
- **Best for small files**: SeaweedFS (O(1) metadata)
- **Best for geo-distribution**: Garage (built-in)

## 🎯 Summary
- Self-hosted + license-safe → **SeaweedFS**
- Edge/homelab → **Garage**
- Decentralized + S3 API → **Storj**
