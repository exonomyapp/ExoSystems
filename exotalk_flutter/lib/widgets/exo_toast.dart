// =============================================================================
// exo_toast.dart — Animated Notification Overlay (Conscia Standard)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/toast_provider.dart';
import '../src/theme.dart';
import '../main.dart';

class ExoToastOverlay extends ConsumerWidget {
  final Widget child;
  const ExoToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(toastProvider);
    final scale = ref.watch(uiScaleProvider);

    return Stack(
      children: [
        child,
        Positioned(
          top: 24.0 * scale,
          right: 24.0 * scale,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 350.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: toasts.map((t) => ExoToastCard(toast: t, scale: scale)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class ExoToastCard extends StatefulWidget {
  final ToastMessage toast;
  final double scale;
  const ExoToastCard({super.key, required this.toast, required this.scale});

  @override
  State<ExoToastCard> createState() => _ExoToastCardState();
}

class _ExoToastCardState extends State<ExoToastCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Human-like weighted curve (starts fast, settles slow)
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _offsetAnimation = Tween<Offset>(
      begin: Offset(1.5, 0.0),
      end: Offset.zero,
    ).animate(curve);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData icon;

    switch (widget.toast.type) {
      case ToastType.success:
        accentColor = Colors.green;
        icon = LucideIcons.checkCircle;
        break;
      case ToastType.error:
        accentColor = ConsciaTheme.error(context);
        icon = LucideIcons.alertTriangle;
        break;
      case ToastType.info:
        accentColor = ConsciaTheme.accent(context);
        icon = LucideIcons.info;
        break;
    }

    return SlideTransition(
        position: _offsetAnimation,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.0 * widget.scale),
          padding: EdgeInsets.all(16.0 * widget.scale),
          decoration: BoxDecoration(
            color: ConsciaTheme.surface(context),
            borderRadius: BorderRadius.circular(16.0 * widget.scale),
            border: Border.all(color: accentColor, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 20.0 * widget.scale),
              SizedBox(width: 12.0 * widget.scale),
              Flexible(
                child: Text(
                  widget.toast.message,
                  style: ConsciaTheme.bodyStyle(context, widget.scale).copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 16.0 * widget.scale),
              Consumer(builder: (context, ref, _) {
                return GestureDetector(
                  onTap: () => ref.read(toastProvider.notifier).dismiss(widget.toast.id),
                  child: Icon(LucideIcons.x, size: 14.0 * widget.scale, color: ConsciaTheme.muted(context)),
                );
              }),
            ],
          ),
        ),
    );
  }
}
