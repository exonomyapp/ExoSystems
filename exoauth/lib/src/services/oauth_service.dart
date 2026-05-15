// =============================================================================
// oauth_service.dart — OAuth Authentication Service
// =============================================================================
//
// This service handles the OAuth 2.0 Authorization Code flow for linking
// auth providers to the user's did:peer identity. These links
// serve as recovery mechanisms — they do not own the identity but allow the
// user to prove identity to a Conscia node during device-loss recovery.
//
// Flow: authorize → exchange code for token → fetch userinfo → return (sub, name)
//
//
// Provider architecture:
//   - Loopback Flow: We utilize a local HTTP server (127.0.0.1:8080) for the 
//     redirect_uri. This ensures that OAuth tokens are captured directly by 
//     the client process without requiring a central proxy server.
//
//   - Identity Integration: OAuth data is used ONLY as a discovery/recovery 
//     mechanism. The user's primary identity remains the `did:peer`.
//
// See: docs/spec/02_identity_and_access.md §2.4.2 for the recovery model.
// =============================================================================

import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'secrets_config.dart'; // Local configuration (GIT-IGNORED)

class OAuthProviderConfig {
  final String id;
  final String name;
  final String authUrl;
  final String tokenUrl;
  final String clientId;
  final String? clientSecret;
  final List<String> scopes;
  final String userinfoUrl;
  final String subPath; // JSON path to stable ID, e.g., 'id' or 'sub'
  final String? namePath; // JSON path to display name, e.g., 'login' or 'name'
  final String? avatarPath; // JSON path to profile picture url

  OAuthProviderConfig({
    required this.id,
    required this.name,
    required this.authUrl,
    required this.tokenUrl,
    required this.clientId,
    this.clientSecret,
    required this.scopes,
    required this.userinfoUrl,
    required this.subPath,
    this.namePath,
    this.avatarPath,
  });

  /// Returns true if real credentials have been provided via environment variables.
  bool get isConfigured => clientId.isNotEmpty && !clientId.startsWith('mock_');
}

class OAuthService {
  static final Map<String, OAuthProviderConfig> builtInProviders = {
    'github': OAuthProviderConfig(
      id: 'github',
      name: 'GitHub',
      authUrl: 'https://github.com/login/oauth/authorize',
      tokenUrl: 'https://github.com/login/oauth/access_token',
      clientId: 'Ov23limEc6P96nOhseHh',
      clientSecret: SecretsConfig.githubClientSecret,
      scopes: ['user:email', 'read:user'],
      userinfoUrl: 'https://api.github.com/user',
      subPath: 'id',
      namePath: 'login',
      avatarPath: 'avatar_url',
    ),
    'discord': OAuthProviderConfig(
      id: 'discord',
      name: 'Discord',
      authUrl: 'https://discord.com/oauth2/authorize',
      tokenUrl: 'https://discord.com/api/oauth2/token',
      clientId: const String.fromEnvironment('EXOTALK_DISCORD_CLIENT_ID', defaultValue: 'mock_discord'),
      scopes: ['identify', 'email'],
      userinfoUrl: 'https://discord.com/api/users/@me',
      subPath: 'id',
      namePath: 'username',
      avatarPath: 'avatar',
    ),
    'google': OAuthProviderConfig(
      id: 'google',
      name: 'Google',
      authUrl: 'https://accounts.google.com/o/oauth2/v2/auth',
      tokenUrl: 'https://oauth2.googleapis.com/token',
      clientId: '713908392428-puvsua0h5dgi4sea57l2achah412dnfo.apps.googleusercontent.com',
      clientSecret: SecretsConfig.googleClientSecret,
      scopes: ['openid', 'email', 'profile'],
      userinfoUrl: 'https://www.googleapis.com/oauth2/v3/userinfo',
      subPath: 'email',
      namePath: 'name',
      avatarPath: 'picture',
    ),
  };

  // Pending review providers that require user-provided Client IDs for now
  static final List<String> pendingReviewProviderIds = [
    'microsoft',
    'twitter',
    'apple',
  ];

  static Future<({String sub, String displayName, String avatarUrl})> authenticate(OAuthProviderConfig config) async {
    final redirectUri = 'http://127.0.0.1:8080';
    
    // 1. Authenticate via WebAuth2
    final result = await FlutterWebAuth2.authenticate(
      url: Uri.parse(config.authUrl).replace(queryParameters: {
        'client_id': config.clientId,
        'response_type': 'code',
        'scope': config.scopes.join(' '),
        'redirect_uri': redirectUri,
      }).toString(),
      callbackUrlScheme: 'http',
      options: const FlutterWebAuth2Options(
        windowName: 'ExoTalk Auth',
      ),
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw Exception('No code returned from auth provider');

    // 2. Exchange code for token
    final tokenResponse = await http.post(
      Uri.parse(config.tokenUrl),
      headers: {'Accept': 'application/json'},
      body: {
        'client_id': config.clientId,
        if (config.clientSecret != null) 'client_secret': config.clientSecret!,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    );

    final tokenData = jsonDecode(tokenResponse.body);
    final accessToken = tokenData['access_token'];
    if (accessToken == null) throw Exception('Failed to get access token');

    // 3. Fetch User Info
    final infoResponse = await http.get(
      Uri.parse(config.userinfoUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    final userData = jsonDecode(infoResponse.body);
    final sub = userData[config.subPath].toString();
    final displayName = config.namePath != null && userData[config.namePath] != null
        ? userData[config.namePath].toString() 
        : "${config.name} user";
        
    final avatarUrl = config.avatarPath != null && userData[config.avatarPath] != null
        ? userData[config.avatarPath].toString()
        : "";

    return (sub: sub, displayName: displayName, avatarUrl: avatarUrl);
  }
}
