import 'identity_service.dart';
import 'models.dart';
import 'rust/api/identity.dart' as api;
import 'rust/frb_generated.dart';

/// Initializes the core Rust cryptography and identity engine.
/// Must be called before using the service.
Future<void> initExoAuthCore() async {
  await RustLib.init();
}

class RustIdentityService implements IdentityService {
  @override
  Future<DeviceManifest> getDeviceManifest() => api.getDeviceManifest();

  @override
  Future<void> saveDeviceManifest(DeviceManifest manifest) => api.saveDeviceManifest(manifest: manifest);

  @override
  Future<IdentityVault> generateNewIdentity() => api.generateNewIdentity();

  @override
  Future<bool> switchActiveProfile(String did) => api.switchActiveProfile(did: did);

  @override
  Future<IdentityVault> getActiveProfileVault() => api.getActiveIdentity();

  @override
  Future<void> signOutProfile() => api.signOutProfile();

  @override
  Future<IdentityVault> updateActiveProfile({required String name, required String avatar}) => 
      api.updateActiveProfile(name: name, avatar: avatar);

  @override
  Future<OAuthLink> addOauthLink({required String provider, required String displayName, required String sub}) => 
      api.addOauthLink(provider: provider, displayName: displayName, sub: sub);

  @override
  Future<void> removeOauthLink(String provider) => api.removeOauthLink(provider: provider);

  @override
  Future<String?> findDidForOauth({required String provider, required String sub}) async {
    final result = await api.findDidForOauth(provider: provider, sub: sub);
    return result.isEmpty ? null : result;
  }

  @override
  Future<String> createProfileFromOauth({
    required String provider,
    required String sub,
    required String name,
    required String avatar,
  }) => api.createProfileFromOauth(provider: provider, sub: sub, name: name, avatar: avatar);

  @override
  Future<void> linkOauthToExistingProfile({
    required String did,
    required String provider,
    required String sub,
  }) => api.linkOauthToExistingProfile(did: did, provider: provider, sub: sub);

  @override
  Future<void> setIngressEnabled({required bool enabled}) async {
    await api.setIngressEnabled(enabled: enabled);
  }

  @override
  Future<void> setEgressEnabled({required bool enabled}) async {
    await api.setEgressEnabled(enabled: enabled);
  }

  @override
  Future<String> generateDevicePairingToken() => api.generateDevicePairingToken();

  @override
  Future<String> exportProfileBundle() => api.exportProfileBundle();

  @override
  Future<bool> importProfileBundle({required String bundle}) => api.importProfileBundle(bundle: bundle);

  @override
  Future<void> discardIdentity(String did) async {
    final manifest = await api.getDeviceManifest();
    final updatedProfiles = manifest.profiles.where((p) => p.did != did).toList();
    await api.saveDeviceManifest(manifest: DeviceManifest(
      tenancyMode: manifest.tenancyMode,
      profiles: updatedProfiles,
      associatedConsciaId: manifest.associatedConsciaId,
    ));
    // Additional cleanup could be done here if Rust exposed a delete API
  }

  @override
  Future<void> pingConscia() async {
    // Legacy support, Conscia endpoint check or no-op
  }

  @override
  Future<String> generateBestProof({required String platform, required BigInt maxChars}) => 
      api.generateBestProof(maxChars: maxChars);

  @override
  Future<void> addVerificationLink({required String platformLabel, required String url}) => 
      api.addVerificationLink(label: platformLabel, url: url);

  @override
  Future<void> confirmVerificationLink({required String url, required bool verified}) => 
      api.confirmVerificationLink(url: url, verified: verified);
}
