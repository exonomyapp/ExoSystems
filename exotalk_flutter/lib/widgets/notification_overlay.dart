import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/notification_provider.dart';
import '../../providers/toast_provider.dart';
import '../../src/theme.dart';

class NotificationOverlay extends ConsumerWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    if (notifications.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Column(
        children: notifications.map((n) => _NotificationTile(notification: n)).toList(),
      ),
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  final ExoNotification notification;
  const _NotificationTile({required this.notification});

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    ref.read(notificationProvider.notifier).remove(widget.notification.id);
  }

  @override
  Widget build(BuildContext context) {
    
    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Material(
          elevation: 12,
          color: Colors.transparent,
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildIcon(widget.notification.type),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.notification.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    widget.notification.message,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              icon: Icon(LucideIcons.x, color: Colors.white24, size: 18),
                            ),
                          ],
                        ),
                        if (widget.notification.type == NotificationType.conflict) ...[
                          SizedBox(height: 20),
                          _buildConflictActions(),
                        ],
                      ],
                    ),
                  ),
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.accent(context)),
                        ),
                      ),
                    ),
                  if (_resolutionSync != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: ConflictResolutionCandy(
                            sync: _resolutionSync!,
                            onComplete: _dismiss,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool? _resolutionSync;

  Widget _buildIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.conflict:
        iconData = LucideIcons.gitBranch;
        color = Colors.amber;
        break;
      case NotificationType.error:
        iconData = LucideIcons.alertCircle;
        color = Colors.redAccent;
        break;
      case NotificationType.warning:
        iconData = LucideIcons.alertTriangle;
        color = Colors.orangeAccent;
        break;
      case NotificationType.info:
        iconData = LucideIcons.info;
        color = AppTheme.accent(context);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.accentDark(context),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  Widget _buildConflictActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _handleConflictResolution(false),
            child: Text("Keep Local"),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent(context),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _handleConflictResolution(true),
            child: Text("Sync Network"),
          ),
        ),
      ],
    );
  }

  void _handleConflictResolution(bool sync) async {
    setState(() {
      _isProcessing = true;
    });
    
    // Simulate some async processing (e.g. Rust backend update)
    await Future.delayed(Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _resolutionSync = sync;
      });
      
      if (sync) {
        ref.read(toastProvider.notifier).show("Metadata Synchronized", type: ToastType.success);
      } else {
        ref.read(toastProvider.notifier).show("Local Identity Preserved", type: ToastType.info);
      }
    }
  }
}

// =============================================================================
// ANIMATION WRAPPERS & UI COMPONENTS
// =============================================================================

class ConflictResolutionCandy extends StatefulWidget {
  final bool sync;
  final VoidCallback onComplete;

  const ConflictResolutionCandy({super.key, required this.sync, required this.onComplete});

  @override
  State<ConflictResolutionCandy> createState() => _ConflictResolutionCandyState();
}

class _ConflictResolutionCandyState extends State<ConflictResolutionCandy> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: widget.sync ? 0.0 : 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
    _slide = Tween<Offset>(begin: Offset.zero, end: widget.sync ? Offset(0, 2) : Offset(2, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
            offset: _slide.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.sync ? AppTheme.accent(context) : AppTheme.surface(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.sync ? LucideIcons.download : LucideIcons.trash2,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          );
      },
    );
  }
}
