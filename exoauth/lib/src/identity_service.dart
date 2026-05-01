import 'models.dart';

/// IdentityService: The programmatic 'Front Door' for all ExoTalk identity operations.
/// 
/// ARCHITECTURAL PHILOSOPHY: Service-First Control.
/// This interface must encapsulate every action a user can take in the UI (e.g., signing in, 
/// adding nodes, syncing). By ensuring every UI button simply calls a method here, 
/// we enable headless emulation and verify that the 'Engine' works independently 
/// of the 'Visuals'.
abstract class IdentityService {
  /// Loads the device manifest containing all registered profiles.
  Future<DeviceManifest> getDeviceManifest();

  /// Persists changes to the device manifest.
  Future<void> saveDeviceManifest(DeviceManifest manifest);

  /// Generates a new sovereign identity (did:peer).
  Future<IdentityVault> generateNewIdentity();

  /// Sets a specific identity as active and initializes its session.
  Future<bool> switchActiveProfile(String did);

  /// Retrieves the fully detailed IdentityVault for the currently active profile.
  Future<IdentityVault> getActiveProfileVault();

  /// Signs out the current active profile and shuts down background tasks.
  Future<void> signOutProfile();

  /// Updates the metadata for the active profile.
  Future<IdentityVault> updateActiveProfile({
    required String name,
    required String avatar,
  });

  /// Links an OAuth identity to the active profile.
  Future<OAuthLink> addOauthLink({
    required String provider,
    required String displayName,
    required String sub,
  });

  /// Removes an OAuth link.
  Future<void> removeOauthLink(String provider);
  
  /// Finds if an OAuth sub is already linked to a DID.
  Future<String?> findDidForOauth({
    required String provider,
    required String sub,
  });

  /// Creates a new sovereign profile using OAuth credentials.
  Future<String> createProfileFromOauth({
    required String provider,
    required String sub,
    required String name,
    required String avatar,
  });

  /// Links an OAuth identity to an existing local profile.
  Future<void> linkOauthToExistingProfile({
    required String did,
    required String provider,
    required String sub,
  });

  // ===========================================================================
  // Network & Synchronization Primitives
  // ===========================================================================

  /// Enables or disables incoming synchronization over the P2P mesh.
  /// 
  /// When true, the device will accept data syncs from authenticated peers.
  Future<void> setIngressEnabled({required bool enabled});

  /// Enables or disables outgoing synchronization broadcasts.
  /// 
  /// When true, the device will proactively push updates to the mesh.
  Future<void> setEgressEnabled({required bool enabled});

  // ===========================================================================
  // Device Pairing & Export
  // ===========================================================================

  /// Generates a one-time cryptographic token for pairing a new device via QR code.
  Future<String> generateDevicePairingToken();

  /// Exports the fully encrypted identity bundle for manual copy-paste transfer.
  Future<String> exportProfileBundle();

  /// Imports an encrypted profile bundle to recover an identity on this device.
  /// 
  /// Returns [true] if the import and signature verification succeeded.
  Future<bool> importProfileBundle({required String bundle});

  /// Discards the identity permanently from the local vault.
  /// 
  /// Note: The did:peer architecture means the identity continues to exist 
  /// on the decentralized mesh, but all local secrets are destroyed.
  Future<void> discardIdentity(String did);

  Future<void> pingConscia();

  // ===========================================================================
  // Identity Proofs
  // ===========================================================================
  Future<String> generateBestProof({required String platform, required BigInt maxChars});
  Future<void> addVerificationLink({required String platformLabel, required String url});
  Future<void> confirmVerificationLink({required String url, required bool verified});
}
