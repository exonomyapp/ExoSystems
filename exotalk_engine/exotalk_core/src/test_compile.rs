use std::str::FromStr;
fn test() {
    let key = iroh::PublicKey::from_str("d24a0da7d6b509a87b5ccbe6b5be576b4a9faca047bfa68a6d7e642d61e14b2d").unwrap();
    let mut addr = iroh::NodeAddr::new(key);
    if let Ok(relay) = "https://euw1-1.relay.iroh.network./".parse() {
        addr = addr.with_relay_url(relay);
    }
}
