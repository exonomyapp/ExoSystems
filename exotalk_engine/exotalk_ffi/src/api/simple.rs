// =============================================================================
// simple.rs — FRB Initialization Entrypoint
// =============================================================================
//
// This module contains the FRB (flutter_rust_bridge) initialization function
// that is called once during app startup. It sets up default logging and
// panic handlers for the Rust side.
//
// Note: The original FRB template included a `greet()` demo function here.
// It has been removed as it served no purpose in the ExoTalk architecture.
// =============================================================================

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Registers default panic hooks and log forwarding so that Rust panics
    // and tracing output are visible in the Flutter debug console.
    flutter_rust_bridge::setup_default_user_utils();

    // Start the telemetry sidecar for agent verification (Spec 19)
    let _ = crate::api::telemetry_server::start_telemetry_server();
}
