# Walkthrough 15: OAuth Onboarding & Home Dashboard Update

This session focused on transitioning ExoTalk to an identity management platform.

## 1. OAuth Onboarding (Google & GitHub)
Manual identity creation has been replaced with an automated OAuth flow.
- **Project Configuration**: Configuration of GCP and GitHub projects for authentication.
- **Loopback Auth**: Implemented a local loopback listener (`http://127.0.0.1:8080`) to handle desktop authentication.
- **Link or Generate**: Users can choose to link their social account to an existing DID or generate a new one using social metadata.

## 2. Notification & Conflict Resolution
A manual resolution flow for identity divergence was introduced.
- **Notification System**: The `NotificationOverlay` provides system-level alerts (Info, Warning, Error, Conflict).
- **Interactive Resolution**: The application prompts the user to "Sync Network" or "Keep Local" when data divergence is detected.
- **UI Feedback**: Choice-specific animations provide feedback for synchronization decisions.

## 3. Home Dashboard
The "Access Local Replica" button was replaced with a mode-aware dashboard.
- **Identity Snapshot**: Displays the active DID fingerprint and tenancy mode.
- **Mesh Traffic Visualization**: Displays networking activity based on whether the system is in Isolated or Multiplexed mode.
- **Primary Action**: "Start New Conversation" button.

## How to Verify
1. **OAuth Flow**: Launch the application and select "Sign in with Google" or "Sign in with GitHub". Verify the browser returns to a populated profile.
2. **Conflict UI**: Use the `NotificationOverlay` to trigger a conflict and test the resolution animations.
3. **Traffic View**: Observe the traffic visualization on the Home Screen and confirm complexity changes based on the tenancy mode.
