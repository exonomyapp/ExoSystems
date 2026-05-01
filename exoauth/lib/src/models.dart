/// Standard identity models for the ExoTalk ecosystem.
/// 
/// These models are designed to be shared across all Flutter-based clients
/// (ExoTalk, CMC, Republet) to ensure a consistent identity experience.
class DeviceManifest {
  final String tenancyMode;
  final List<ProfileRecord> profiles;
  final String? associatedConsciaId;

  const DeviceManifest({
    required this.tenancyMode,
    required this.profiles,
    this.associatedConsciaId,
  });
}

class ProfileRecord {
  final String did;
  final String displayName;
  final String avatarUrl;
  final List<String> oauthSubs;

  const ProfileRecord({
    required this.did,
    required this.displayName,
    required this.avatarUrl,
    required this.oauthSubs,
  });
}

class IdentityVault {
  final String did;
  final String secret;
  final String displayName;
  final String avatarUrl;
  final String proofString;
  final List<VerifiedLink> verifiedLinks;
  final List<OAuthLink> oauthLinks;
  final List<NameRecord> nameHistory;
  final bool ingressEnabled;
  final bool egressEnabled;

  const IdentityVault({
    required this.did,
    required this.secret,
    required this.displayName,
    required this.avatarUrl,
    required this.proofString,
    required this.verifiedLinks,
    required this.oauthLinks,
    required this.nameHistory,
    required this.ingressEnabled,
    required this.egressEnabled,
  });
}

class OAuthLink {
  final String provider;
  final String displayName;
  final String sub;
  final String bindingProof;
  final int linkedAtMs;

  const OAuthLink({
    required this.provider,
    required this.displayName,
    required this.sub,
    required this.bindingProof,
    required this.linkedAtMs,
  });
}

class VerifiedLink {
  final String platformLabel;
  final String url;
  final bool isVerified;
  final int verifiedAtMs;

  const VerifiedLink({
    required this.platformLabel,
    required this.url,
    required this.isVerified,
    required this.verifiedAtMs,
  });
}

class NameRecord {
  final String name;
  final String proofString;
  final List<VerifiedLink> verifiedLinks;
  final int activeFromMs;
  final int retiredAtMs;
  final String changeCertificate;

  const NameRecord({
    required this.name,
    required this.proofString,
    required this.verifiedLinks,
    required this.activeFromMs,
    required this.retiredAtMs,
    required this.changeCertificate,
  });
}
