use exotalk_core::network_internal;
use tokio;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // We don't need to start the full node to just see what the potential ID would be if we have the keys,
    // but better to just start it briefly.
    // Actually, we can check if there are keys in exotalk_storage.
    
    let stats = network_internal::get_stats().await;
    println!("Node ID: {}", stats.get("node_id").unwrap_or(&"Not Started".to_string()));
    Ok(())
}
