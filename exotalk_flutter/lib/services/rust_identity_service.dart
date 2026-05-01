import 'package:exoauth/exoauth.dart';
import '../src/rust/api/network.dart' as net;
import '../src/rust/api/willow.dart' as rust;

/// Implementation of [IdentityService] that delegates to the Rust backend.
class RustIdentityService implements IdentityService {
  @override
  Future<DeviceManifest> getDeviceManifest() async {
    final manifest = await rust.getDeviceManifest();
    return DeviceManifest(
      tenancyMode: manifest.tenancyMode,
      profiles: manifest.profiles.map((p) => ProfileRecord(
        did: p.did,
        displayName: p.displayName,
        avatarUrl: p.avatarUrl,
        oauthSubs: p.oauthSubs,
      )).toList(),
      associatedConsciaId: manifest.associatedConsciaId,
    );
  }

  @override
  Future<void> saveDeviceManifest(DeviceManifest manifest) async {
    await rust.saveDeviceManifest(
      manifest: rust.DeviceManifest(
        tenancyMode: manifest.tenancyMode,
        profiles: manifest.profiles.map((p) => rust.ProfileRecord(
          did: p.did,
          displayName: p.displayName,
          avatarUrl: p.avatarUrl,
          oauthSubs: p.oauthSubs,
        )).toList(),
        associatedConsciaId: manifest.associatedConsciaId,
      ),
    );
  }

  @override
  Future<IdentityVault> generateNewIdentity() async {
    final vault = await rust.generateNewIdentity();
    return _mapVault(vault);
  }

  @override
  Future<bool> switchActiveProfile(String did) async {
    return await rust.switchActiveProfile(did: did);
  }

  @override
  Future<IdentityVault> getActiveProfileVault() async {
    final vault = await rust.getActiveIdentity();
    return _mapVault(vault);
  }

  @override
  Future<void> pingConscia() async {
    try {
      await net.forceHandshake();
    } catch (e) {
      // If no node is associated, we just fail silently as per the UI contract
    }
  }

  @override
  Future<void> signOutProfile() async {
    // Hard teardown of the network layer to prevent "Zombie Peers"
    try {
      await net.shutdownNetwork();
    } catch (e) {
      // Log but continue
    }
    await rust.signOutProfile();
  }

  @override
  Future<IdentityVault> updateActiveProfile({
    required String name,
    required String avatar,
  }) async {
    final vault = await rust.updateActiveProfile(name: name, avatar: avatar);
    return _mapVault(vault);
  }

  @override
  Future<OAuthLink> addOauthLink({
    required String provider,
    required String displayName,
    required String sub,
  }) async {
    final link = await rust.addOauthLink(
      provider: provider,
      displayName: displayName,
      sub: sub,
    );
    return OAuthLink(
      provider: link.provider,
      displayName: link.displayName,
      sub: link.sub,
      bindingProof: link.bindingProof,
      linkedAtMs: link.linkedAtMs.toInt(),
    );
  }

  @override
  Future<void> removeOauthLink(String provider) async {
    await rust.removeOauthLink(provider: provider);
  }

  @override
  Future<String?> findDidForOauth({
    required String provider,
    required String sub,
  }) async {
    final did = await rust.findDidForOauth(provider: provider, sub: sub);
    return did.isEmpty ? null : did;
  }

  @override
  Future<String> createProfileFromOauth({
    required String provider,
    required String sub,
    required String name,
    required String avatar,
  }) async {
    return await rust.createProfileFromOauth(
      provider: provider,
      sub: sub,
      name: name,
      avatar: avatar,
    );
  }

  @override
  Future<void> linkOauthToExistingProfile({
    required String did,
    required String provider,
    required String sub,
  }) async {
    await rust.linkOauthToExistingProfile(
      did: did,
      provider: provider,
      sub: sub,
    );
  }

  @override
  Future<void> setIngressEnabled({required bool enabled}) async {
    await rust.setIngressEnabled(enabled: enabled);
  }

  @override
  Future<void> setEgressEnabled({required bool enabled}) async {
    await rust.setEgressEnabled(enabled: enabled);
  }

  @override
  Future<String> generateDevicePairingToken() async {
    return await rust.generateDevicePairingToken();
  }

  @override
  Future<String> exportProfileBundle() async {
    return await rust.exportProfileBundle();
  }

  @override
  Future<bool> importProfileBundle({required String bundle}) async {
    return await rust.importProfileBundle(bundle: bundle);
  }

  @override
  Future<void> discardIdentity(String did) async {
    // No dedicated FFI delete — sign out the profile and remove it from
    // the device manifest, which wipes local secrets.
    await rust.signOutProfile();
    final manifest = await rust.getDeviceManifest();
    final filtered = manifest.profiles.where((p) => p.did != did).toList();
    await rust.saveDeviceManifest(
      manifest: rust.DeviceManifest(
        tenancyMode: manifest.tenancyMode,
        profiles: filtered,
        associatedConsciaId: manifest.associatedConsciaId,
      ),
    );
  }


  @override
  Future<String> generateBestProof({required String platform, required BigInt maxChars}) async {
    // The Rust FFI only takes maxChars — platform is used by the UI layer
    // to select character limits but is not forwarded to the crypto engine.
    return await rust.generateBestProof(maxChars: maxChars);
  }

  @override
  Future<void> addVerificationLink({required String platformLabel, required String url}) async {
    // Rust FFI uses 'label' not 'platformLabel'
    await rust.addVerificationLink(label: platformLabel, url: url);
  }

  @override
  Future<void> confirmVerificationLink({required String url, required bool verified}) async {
    await rust.confirmVerificationLink(url: url, verified: verified);
  }

  IdentityVault _mapVault(rust.IdentityVault v) {
    return IdentityVault(
      did: v.did,
      secret: v.secret,
      displayName: v.displayName,
      avatarUrl: v.avatarUrl,
      proofString: v.proofString,
      verifiedLinks: v.verifiedLinks.map((l) => VerifiedLink(
        platformLabel: l.platformLabel,
        url: l.url,
        isVerified: l.isVerified,
        verifiedAtMs: l.verifiedAtMs.toInt(),
      )).toList(),
      oauthLinks: v.oauthLinks.map((l) => OAuthLink(
        provider: l.provider,
        displayName: l.displayName,
        sub: l.sub,
        bindingProof: l.bindingProof,
        linkedAtMs: l.linkedAtMs.toInt(),
      )).toList(),
      nameHistory: v.nameHistory.map((n) => NameRecord(
        name: n.name,
        proofString: n.proofString,
        verifiedLinks: n.verifiedLinks.map((l) => VerifiedLink(
          platformLabel: l.platformLabel,
          url: l.url,
          isVerified: l.isVerified,
          verifiedAtMs: l.verifiedAtMs.toInt(),
        )).toList(),
        activeFromMs: n.activeFromMs.toInt(),
        retiredAtMs: n.retiredAtMs.toInt(),
        changeCertificate: n.changeCertificate,
      )).toList(),
      ingressEnabled: v.ingressEnabled,
      egressEnabled: v.egressEnabled,
    );
  }
}
