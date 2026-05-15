// --- EXO_TALK CORE ENGINE ---
// This crate represents the engine un-opinionated about its UI.
// It contains all the P2P networking, cryptographic identity, and Willow protocol
// data structures. Any application (Mobile, Desktop, Headless Daemon) can embed
// this engine to synchronize data.

pub mod network_internal;
pub mod protocol_internal;
