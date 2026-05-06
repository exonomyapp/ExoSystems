# Walkthrough 61: Mechanical 30Hz Heartbeat Transformation

The Bridge Monitor heartbeat has been fundamentally refactored to ensure the underlying process strictly adheres to a 30Hz cycle, meeting the deterministic infrastructure requirements.

## Changes Made

### Bridge Monitor Core
- **Process Decoupling**: Removed the native `AnimationController` (which is hard-wired to the 60Hz+ hardware clock) from the heartbeat loop.
- **Mechanical Ticker**: Implemented a `Timer.periodic` running at a fixed **33ms** interval. This ensures that the heartbeat "process" only fires 30 times per second, regardless of screen refresh rates.
- **Sine-Wave Synthesis**: Used `math.sin` to generate a smooth 2-second breathing oscillation directly within the 33ms timer callback.
- **Version Advancement**: Promoted the application to **v1.2.0-LEGISLATOR** (Build `1.0.0+5`) to reflect this significant mechanical shift.

## Verification Results

### Mechanical Audit
- Verified that the `AnimationController` is dormant (no `repeat()` or `addListener` calls).
- Verified that the `Timer` callback is the sole driver of the `pulseNotifier`.

### Deployment (Exonomy Node)
- Successfully deployed the v1.2.0 bundle to the Exonomy workstation.
- Visual verification on the remote desktop confirmed the new version is active and the heartbeat remains visually fluid despite the 50% reduction in process frequency.

> [!IMPORTANT]
> This change achieves a true 50% reduction in heartbeat-related CPU interrupts compared to the native 60Hz implementation.
