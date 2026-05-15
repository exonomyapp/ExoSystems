// =============================================================================
// chat_provider.dart — Riverpod State Management Layer
// =============================================================================
//
// This file defines the Riverpod providers that interface the Rust backend 
// to the widget tree:
//
//   UserProfileNotifier  — The active user's identity (DID, name, avatar, proofs,
//                           OAuth links). Reads from identity storage on init
//                           and after any mutation (rename, verify, link).
//
//   ConversationListNotifier — Global list of conversations. Loaded from Rust on
//                               startup, updated locally on create.
//
//   ActiveConversationIdNotifier — Which conversation is currently selected in the
//                                   sidebar. Drives the ChatWindowScreen.
//
//   MessageListNotifier — Messages for a SPECIFIC conversation, keyed by convo ID.
//                          Uses FamilyNotifier so each conversation has independent
//                          state, preventing cross-chat rebuilds.
//
// Data flow: Identity storage (JSON) → FRB bridge → Provider state → UI widgets
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../src/rust/api/messaging.dart';
import 'package:exoauth/exoauth.dart';

// --- MODELS ---

class UserProfile {
  final String name;
  final String did;
  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final bool isVerified;
  final String proofString;
  final List<VerifiedLink> verifiedLinks;
  final List<NameRecord> nameHistory;
  final List<OAuthLink> linkedAccounts;
  final String secret;
  final bool ingressEnabled;
  final bool egressEnabled;

  UserProfile({
    required this.name,
    required this.did,
    required this.secret,
    this.avatarBytes,
    this.avatarUrl,
    this.isVerified = false,
    this.proofString = '',
    this.verifiedLinks = const [],
    this.nameHistory = const [],
    this.linkedAccounts = const [],
    this.ingressEnabled = true,
    this.egressEnabled = true,
  });
}

// --- PROVIDERS ---

/// Manages the active user's identity and profile. This notifier maintains 
/// the identity state across the application, ensuring that 
/// all components react to identity changes or storage updates.
class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    _initIdentity();
    return UserProfile(name: 'Me', did: 'did:me:loading...', secret: '');
  }

  Future<void> _initIdentity() async {
    await refreshFromStorage();
  }

  Future<void> refreshFromStorage() async {
    final identityData = await getActiveIdentity();
    if (identityData.did.isEmpty) {
      debugPrint("UserProfileNotifier: No active profile session.");
      state = UserProfile(name: 'Signed Out', did: '', secret: '');
      return;
    }
    
    String? url = identityData.avatarUrl.isEmpty ? null : identityData.avatarUrl;
    Uint8List? bytes;
    if (url != null && url.startsWith('data:image')) {
      try {
        bytes = base64Decode(url.split(',').last);
      } catch (_) {}
    }
    state = UserProfile(
      name: identityData.displayName, 
      did: identityData.did, 
      avatarUrl: identityData.avatarUrl,
      avatarBytes: bytes,
      isVerified: identityData.verifiedLinks.any((l) => l.isVerified),
      proofString: identityData.proofString,
      verifiedLinks: identityData.verifiedLinks,
      nameHistory: identityData.nameHistory,
      linkedAccounts: await getOauthLinks(),
      secret: identityData.secret,
      ingressEnabled: identityData.ingressEnabled,
      egressEnabled: identityData.egressEnabled,
    );
  }

  Future<void> updateProfile(String name, String did, Uint8List? bytes, String? url) async {
    final identityData = await updateActiveProfile(name: name, avatar: url ?? "");
    state = UserProfile(
      name: identityData.displayName, 
      did: identityData.did, 
      avatarBytes: bytes, 
      avatarUrl: identityData.avatarUrl,
      secret: identityData.secret,
      verifiedLinks: identityData.verifiedLinks,
      nameHistory: identityData.nameHistory,
      proofString: identityData.proofString,
      ingressEnabled: identityData.ingressEnabled,
      egressEnabled: identityData.egressEnabled,
    );
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile>(() => UserProfileNotifier());

/// Manages the global list of conversations.
class ConversationListNotifier extends Notifier<List<Conversation>> {
  @override
  List<Conversation> build() {
    _refreshConversations();
    return const [];
  }

  Future<void> _refreshConversations() async {
    try {
      final convos = await fetchConversations();
      state = convos;
    } catch (_) {}
  }

  /// Creates a new conversation and sets it as active.
  /// [peerDid] is the target peer's DID for 1-on-1 chats. If null (group chats),
  /// an empty peers list is used and members are added later via GroupManager.
  Future<void> createNew(String title, {String? peerDid}) async {
    final peers = peerDid != null && peerDid.isNotEmpty ? [peerDid] : <String>[];
    final convo = await createConversation(title: title, peers: peers);
    state = [...state, convo];
    // Set as active so the UI immediately navigates to the new conversation
    ref.read(activeConversationIdProvider.notifier).set(convo.id);
  }

  /// Updates the title of a conversation locally.
  void rename(String id, String newTitle) {
    state = [
      for (final convo in state)
        if (convo.id == id)
          Conversation(
            id: convo.id,
            title: newTitle,
            peers: convo.peers,
            lastActive: convo.lastActive,
            unreadCount: convo.unreadCount,
            avatar: convo.avatar,
            isGroup: convo.isGroup,
          )
        else
          convo
    ];
  }

  /// Removes a conversation from the local list and deletes it from the backend.
  Future<void> delete(String id) async {
    if (ref.read(activeConversationIdProvider) == id) {
      ref.read(activeConversationIdProvider.notifier).set(null);
    }
    state = state.where((convo) => convo.id != id).toList();
    await deleteConversation(convoId: id);
  }
}

final conversationListProvider = NotifierProvider<ConversationListNotifier, List<Conversation>>(() => ConversationListNotifier());

/// Manages the currently selected conversation ID.
class ActiveConversationIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    if (state != id) {
      state = id;
    }
  }
}

final activeConversationIdProvider = NotifierProvider<ActiveConversationIdNotifier, String?>(() => ActiveConversationIdNotifier());

final searchQueryProvider = StateProvider<String>((ref) => "");

final filteredConversationsProvider = Provider<List<Conversation>>((ref) {
  final conversations = ref.watch(conversationListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  
  if (query.isEmpty) return conversations;
  
  return conversations.where((convo) {
    // Check title, ID, and all participant DIDs
    final matchesTitle = convo.title.toLowerCase().contains(query);
    final matchesId = convo.id.toLowerCase().contains(query);
    final matchesPeers = convo.peers.any((peerDid) => peerDid.toLowerCase().contains(query));
    
    return matchesTitle || matchesId || matchesPeers;
  }).toList();
});

/// Manages messages for a SPECIFIC conversation.
/// By utilizing FamilyNotifier keyed to the conversation ID, we achieve 
/// total isolation of message streams. This prevents "cross-chat" rebuild 
/// pollution and ensures that UI performance remains deterministic even 
/// with dozens of active mesh conversations.
class MessageListNotifier extends FamilyNotifier<List<Message>, String> {
  @override
  List<Message> build(String arg) {
    _loadMessages();
    return const [];
  }

  Future<void> _loadMessages() async {
    final msgs = await getMessagesForConversation(convoId: arg);
    state = msgs;
  }

  Future<void> send(String content) async {
    final user = ref.read(userProfileProvider);
    final newMsg = await sendMessage(
      conversationId: arg,
      authorDid: user.did,
      content: content,
    );
    state = [...state, newMsg];
  }
}

final messagesProvider = NotifierProviderFamily<MessageListNotifier, List<Message>, String>(() => MessageListNotifier());
