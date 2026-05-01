# Spec 18: Identity Lifecycle Events

This document specifies the end-to-end event history for identity transitions (Sign-In and Sign-Out) within the ExoTalk application, detailing UI interactions, state management triggers, and background service coordination.

## 1. Sign-In Flow (The "Front Door")

The Sign-In flow transitions the application from a dormant/unauthenticated state to an active P2P mesh participant.

### 1.1 UI Initiation
1.  **Entry Point**: `WelcomeScreen` displays a list of known `IdentityVault` profiles (retrieved from `getDeviceManifest` in Rust).
2.  **User Action**: User clicks an identity tile or confirms a new identity generation.
3.  **Trigger**: UI calls `ref.read(identityProvider.notifier).switchIdentity(did)`.

### 1.2 Provider Logic (`IdentityManager`)
1.  **Loading State**: `IdentityState.isLoading` is set to `true`. UI shows a progress indicator.
2.  **Engine Sync**: Calls the Rust FFI function `switchActiveProfile(did)`. The Rust engine loads the corresponding Willow identity vault and initializes the Iroh QUIC endpoint for that DID.
3.  **Data Hydration**: 
    -   Calls `userProfileProvider.notifier.refreshFromVault()`. This fetches the latest metadata (display name, avatar, capabilities) from the Rust vault.
    -   Invalidates `activeConversationIdProvider` and `conversationListProvider` to ensure the next screen fetches data specific to the new DID.
4.  **Session Commit**: `IdentityState.activeDid` is updated to the target DID. `isLoading` is set to `false`.

### 1.3 Routing Transition
1.  **AppRouter Build**: `AppRouter` (watching `identityProvider`) detects that `activeDid` is no longer null.
2.  **Animation**: `AnimatedSwitcher` begins a **500ms fade transition** between `WelcomeScreen` and `HomeScreen`.
3.  **HomeScreen Mount**: `HomeScreen` initializes, starting hardware keyboard listeners and mesh traffic animation controllers.

---

## 2. Sign-Out Flow (The "Graceful Exit")

The Sign-Out flow ensures background services are terminated and local caches are wiped without causing UI assertion errors during unmounting.

### 2.1 UI Initiation
1.  **Entry Point**: User selects "Sign Out" from the Identity Switcher dropdown, clicks the red "Exit" button in the status footer, or uses the **Esc key** hierarchy from the root dashboard.
2.  **Trigger**: UI calls `ref.read(identityProvider.notifier).signOut()`.

### 2.2 Provider Logic (`IdentityManager`)
1.  **Phase 1: Visual Lock**:
    -   `IdentityState.isSigningOut` is set to `true`.
    -   `HomeScreen` responds by wrapping the entire layout in an `IgnorePointer` and 50% `Opacity` with a grayscale `ColorFilter`.
    -   **Timer**: A **1500ms artificial delay** is introduced. This gives the user visual confirmation of the logout and prevents accidental double-clicks.
2.  **Phase 2: Engine Shutdown**:
    -   Calls the Rust FFI function `signOutProfile()`. This halts Willow synchronization, closes the Iroh gossip overlay, and releases file locks on the local identity database.
3.  **Phase 3: Routing Redirect**:
    -   `IdentityState.activeDid` is set to `null`.
    -   `IdentityState.isSigningOut` is set to `false`.
    -   **AppRouter Build**: `AppRouter` detects `activeDid == null` and starts the **500ms fade-out** of `HomeScreen`.

### 2.3 Provider Logic (Delayed Cleanup)
To prevent "Failed assertion: _dependents.isEmpty" crashes (where unmounting widgets try to read disposed providers), the final cache wipe is delayed.

1.  **Safety Guard**: A **1000ms delay** (`Future.delayed`) is triggered *after* the `activeDid` was cleared.
2.  **Cache Invalidation**: Once the `HomeScreen` is guaranteed to be unmounted and removed from the widget tree, the following providers are invalidated:
    -   `userProfileProvider`
    -   `activeConversationIdProvider`
    -   `conversationListProvider`
    -   `consciaStatusProvider`
    -   `governanceProvider`

### 2.4 Final State
The application returns to the `WelcomeScreen`. All P2P networking is halted, and no sensitive identity data remains in the active memory of the Flutter providers.

---

## 3. Keyboard-First Interactions

In accordance with ExoTalk's "Keyboard-First" philosophy, identity lifecycle events are deeply integrated with global keystroke listeners.

### 3.1 Sign-Out via `Esc` Key
The `HomeScreen` implements a global `HardwareKeyboard` handler that manages a hierarchical "unwind" of the UI state:

1.  **Level 1: Unfocus**: If an `EditableText` (search bar or chat input) is focused, the first `Esc` press unfocuses it.
2.  **Level 2: View Exit**: If the user is in a sub-view (e.g., `NodeManagementView`), the next `Esc` press returns them to the primary `ChatView`.
3.  **Level 3: Conversation Close**: If a specific chat is open, the next `Esc` press closes the chat and returns to the home dashboard.
4.  **Level 4: Sign-Out Trigger**: If the user is already at the root dashboard, the final `Esc` press triggers the **Sign-Out Confirmation Dialog**.

### 3.2 Dialog Navigation
Once the Sign-Out dialog is visible:
-   **Enter**: Confirms the sign-out and initiates the flow described in Section 2.
-   **Esc**: Closes the dialog and returns the user to the dashboard.

### 3.3 Zoom and Scaling
Global `Ctrl` shortcuts (managed in `main.dart`) allow for persistent UI scaling, which is preserved across identity transitions:
-   **Ctrl + / Ctrl -**: Increments/decrements the `uiScaleProvider` by 0.05x.
-   **Ctrl 0**: Resets the scale to 1.0x.

