// toast_provider.dart — Notification State Management
// =============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

enum ToastType { info, success, error }

class ToastMessage {
  final String id;
  final String message;
  final ToastType type;
  final Duration duration;

  ToastMessage({
    required this.id,
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 4),
  });
}

class ToastNotifier extends StateNotifier<List<ToastMessage>> {
  ToastNotifier() : super([]);

  void show(String message, {ToastType type = ToastType.info}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final toast = ToastMessage(id: id, message: message, type: type);
    
    state = [...state, toast];

    // Auto-dismiss logic
    Timer(toast.duration, () {
      dismiss(id);
    });
  }

  void dismiss(String id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final toastProvider = StateNotifierProvider<ToastNotifier, List<ToastMessage>>((ref) {
  return ToastNotifier();
});
