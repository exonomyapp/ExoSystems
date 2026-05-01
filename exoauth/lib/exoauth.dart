library exoauth;

// Public Surface API
export 'src/models.dart' show ProfileRecord, IdentityVault, OAuthLink, VerifiedLink, NameRecord, DeviceManifest;
export 'src/identity_service.dart' show IdentityService;
export 'src/providers.dart' show identityProvider, IdentityController, IdentityState, identityServiceProvider, uiScaleProvider, authToastProvider;
export 'src/screens/exo_auth_view.dart' show ExoAuthView;
export 'src/theme.dart' show ConsciaTheme, sharedPreferencesProvider, themeModeProvider;
export 'src/widgets/danger_zone.dart' show DangerZone, DangerZoneItem;
export 'src/widgets/account_manager.dart' show AccountManagerModal;
export 'src/widgets/device_pairing_modal.dart' show DevicePairingModal;

// Note: Internal widgets and services are hidden within src/
