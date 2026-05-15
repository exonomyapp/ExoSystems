import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';

enum ConsoulCapability {
  operationalPulse,
  authorityMatrix,
  governance,
  federationAdministration,
  serviceAdministration,
  geographicContext,
}

// 🧠 EDUCATIONAL CONTEXT: SDUI Catch-22 Resolution
// Capabilities and UI blueprints are pulled natively from the local Willow Data Store
// (populated via gossiped topics) rather than relying on centralized authentication servers.
// For now, this provider returns a root bootstrap payload if authenticated.
//
// 💡 MENTOR TIP: Progressive Disclosure
// This provider is the engine of the 'Progressive Disclosure' architecture. 
// By returning a list of capabilities, we tell the 'ConSoul' widget exactly 
// which tabs and controls are available to the current identity. In the future, 
// this list will be dynamically fetched from the Conscia daemon's 
// /api/capabilities endpoint.
final capabilitiesProvider = Provider<List<ConsoulCapability>>((ref) {
  final identityState = ref.watch(identityProvider);
  final isAuthenticated = identityState.activeDid != null;

  if (isAuthenticated) {
    return [
      ConsoulCapability.operationalPulse,
      ConsoulCapability.authorityMatrix,
      ConsoulCapability.governance,
      ConsoulCapability.federationAdministration,
      ConsoulCapability.serviceAdministration,
      ConsoulCapability.geographicContext,
    ];
  } else {
    return [
      ConsoulCapability.operationalPulse,
    ];
  }
});
