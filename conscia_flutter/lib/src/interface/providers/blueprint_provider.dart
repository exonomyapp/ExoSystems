import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';

enum ConsoulCapability {
  operationalPulse,
  authorityMatrix,
  sovereignGovernance,
  federationAdministration,
}

// 🧠 EDUCATIONAL CONTEXT: SDUI Catch-22 Resolution
// Capabilities and UI blueprints are pulled natively from the local Willow Data Store
// (populated via gossiped topics) rather than relying on centralized authentication servers.
// For now, this provider returns a root bootstrap payload if authenticated.
final capabilitiesProvider = Provider<List<ConsoulCapability>>((ref) {
  final identityState = ref.watch(identityProvider);
  final isAuthenticated = identityState.activeDid != null;

  if (isAuthenticated) {
    return [
      ConsoulCapability.operationalPulse,
      ConsoulCapability.authorityMatrix,
      ConsoulCapability.sovereignGovernance,
      ConsoulCapability.federationAdministration,
    ];
  } else {
    return [
      ConsoulCapability.operationalPulse,
    ];
  }
});
