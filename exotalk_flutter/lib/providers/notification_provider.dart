import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType {
  info,
  warning,
  error,
  conflict,
}

class ExoNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  ExoNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationNotifier extends StateNotifier<List<ExoNotification>> {
  NotificationNotifier() : super([]);

  void notify(ExoNotification notification) {
    state = [...state, notification];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<ExoNotification>>((ref) {
  return NotificationNotifier();
});
