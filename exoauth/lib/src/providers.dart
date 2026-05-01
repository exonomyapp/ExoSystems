import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'identity_service.dart';

/// The state for the IdentityManager.
class IdentityState {
  final String? activeDid;
  final IdentityVault? activeVault;
  final List<ProfileRecord> knownIdentities;
  final String tenancyMode; // "Isolated" or "Multiplexed"
  final bool isSigningOut;
  final bool isLoading;

  IdentityState({
    this.activeDid,
    this.activeVault,
    this.knownIdentities = const [],
    this.tenancyMode = 'Isolated',
    this.isSigningOut = false,
    this.isLoading = false,
  });

  IdentityState copyWith({
    String? activeDid,
    bool clearActiveDid = false,
    IdentityVault? activeVault,
    bool clearActiveVault = false,
    List<ProfileRecord>? knownIdentities,
    String? tenancyMode,
    bool? isSigningOut,
    bool? isLoading,
  }) {
    return IdentityState(
      activeDid: clearActiveDid ? null : (activeDid ?? this.activeDid),
      activeVault: clearActiveVault ? null : (activeVault ?? this.activeVault),
      knownIdentities: knownIdentities ?? this.knownIdentities,
      tenancyMode: tenancyMode ?? this.tenancyMode,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Abstract provider for the IdentityService implementation.
/// This must be overridden in the app's ProviderScope.
final identityServiceProvider = Provider<IdentityService>((ref) {
  throw UnimplementedError('identityServiceProvider not overridden');
});

/// Manages the identity lifecycle, delegated to an IdentityService.
class IdentityController extends Notifier<IdentityState> {
  IdentityService get _service => ref.read(identityServiceProvider);

  @override
  IdentityState build() {
    _loadStoredIdentities();
    return IdentityState(isLoading: true);
  }

  Future<void> refreshManifest() async {
    await _loadStoredIdentities();
  }

  Future<void> refreshActiveVault() async {
    if (state.activeDid == null) return;
    try {
      final vault = await _service.getActiveProfileVault();
      state = state.copyWith(activeVault: vault);
    } catch (_) {}
  }

  Future<void> _loadStoredIdentities() async {
    try {
      final manifest = await _service.getDeviceManifest();
      
      state = state.copyWith(
        knownIdentities: manifest.profiles,
        tenancyMode: manifest.tenancyMode,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Switches the active identity context.
  Future<bool> switchIdentity(String did) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final success = await _service.switchActiveProfile(did);
      
      if (success) {
        final vault = await _service.getActiveProfileVault();
        state = state.copyWith(activeDid: did, activeVault: vault, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  /// Signs out the current active profile.
  Future<void> signOut() async {
    try {
      state = state.copyWith(isSigningOut: true);
      
      // Artificial delay for UI feedback as per legacy protocol
      await Future.delayed(const Duration(milliseconds: 1500));
      
      await _service.signOutProfile();
    } catch (e) {
      // Log error but proceed to clear state
    } finally {
      state = state.copyWith(
        clearActiveDid: true,
        clearActiveVault: true,
        isSigningOut: false,
        isLoading: false,
      );
    }
  }

  /// Permanently removes an identity.
  Future<void> discardIdentity(String did) async {
    if (state.activeDid == did) {
      await signOut();
    }

    try {
      final manifest = await _service.getDeviceManifest();
      final updatedProfiles = manifest.profiles.where((p) => p.did != did).toList();
      
      await _service.saveDeviceManifest(DeviceManifest(
        tenancyMode: manifest.tenancyMode,
        profiles: updatedProfiles,
        associatedConsciaId: manifest.associatedConsciaId,
      ));

      await refreshManifest();
    } catch (_) {}
  }
}

/// The global identity provider.
final identityProvider = NotifierProvider<IdentityController, IdentityState>(() => IdentityController());

/// Global UI scale factor for ConsciaTheme and WelcomeScreen.
/// Host apps should override this if they have a dynamic scaling feature.
final uiScaleProvider = StateProvider<double>((ref) => 1.0);

/// Host-provided toast function.
final authToastProvider = Provider<void Function(String message, {bool isError})>((ref) => (message, {isError = false}) {});
