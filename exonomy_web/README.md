# Exonomy Indexing Node (Web)

This is the Rust backend and Flutter Web dashboard for the Exonomy Blind Indexing Service. It provides high-availability search indexing for public vouchers without compromising payload custody.

## Architecture & Topology
For a complete understanding of how this indexing node fits into the ecosystem, please refer to:
[Exonomy Topology Specification](../docs/spec/23_exonomy_topology.md)

## Development
```bash
# Rust backend
cargo run

# Flutter Web dashboard
flutter run -d chrome
```
