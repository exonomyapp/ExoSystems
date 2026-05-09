use std::time::Duration;
use flutter_rust_bridge::frb;
use crate::frb_generated::StreamSink;

/// 🧠 Educational Context: Moses Breathing Pulse
/// This stream generates a smooth, organic breathing rhythm for the "Sleep" (Yellow) light.
/// By squaring the sine wave, we create a bell-curve effect that lingers at the 
/// extremities, mimicking a biological breath instead of a mechanical triangle wave.
#[frb(sync)]
pub fn breathing_pulse_stream(sink: StreamSink<f32>) {
    std::thread::spawn(move || {
        let mut t: f32 = 0.0;
        loop {
            // Calculate a squared sine wave for a "bell curve" breathing effect.
            // Frequency is roughly 0.5Hz (2-second breath cycle).
            let value = t.sin().powi(2); 
            
            // Send the value to Dart.
            if sink.add(value).is_err() {
                break; // Stream closed
            }
            
            t += 0.05; // Step frequency
            std::thread::sleep(Duration::from_millis(33)); // ~30Hz update rate
        }
    });
}

/// 🧠 Educational Context: Zero-Allocation Health
/// A simple ping-pong to verify the bridge integrity without overhead.
#[frb(sync)]
pub fn ping() -> String {
    "pong".to_string()
}
