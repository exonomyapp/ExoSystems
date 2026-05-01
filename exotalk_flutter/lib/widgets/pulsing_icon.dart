import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../src/theme.dart';

class PulsingNodeIcon extends StatefulWidget {
  final bool isSleeping;
  final double scale;
  final double? iconSize;

  const PulsingNodeIcon({super.key, required this.isSleeping, required this.scale, this.iconSize});

  @override
  State<PulsingNodeIcon> createState() => _PulsingNodeIconState();
}

class _PulsingNodeIconState extends State<PulsingNodeIcon> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _setupAnimation();
  }

  @override
  void didUpdateWidget(PulsingNodeIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSleeping != widget.isSleeping) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    _controller.duration = Duration(milliseconds: widget.isSleeping ? 2000 : 1000);
    
    // Active Server: Pulse from 1.0 (base) down to 0.3 (high intensity glow)
    // Sleeping Moon: Pulse from 1.0 (base) down to 0.4 (bright/light orange glow)
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.isSleeping ? 0.4 : 0.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = (widget.iconSize ?? 16.0) * widget.scale;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final amountToBrighten = 1.0 - _animation.value;
          
          if (widget.isSleeping) {
            // Sleeping mode: Lighter orange glow
            final baseColor = ConsciaTheme.warning(context);
            final blendedColor = Color.lerp(baseColor, Colors.white, amountToBrighten) ?? baseColor;
            
            return Icon(
              LucideIcons.moon,
              size: size,
              color: blendedColor,
            );
          } else {
            // Active mode: High-intensity green glow
            final baseColor = ConsciaTheme.accent(context);
            final blendedColor = Color.lerp(baseColor, Colors.white, amountToBrighten) ?? baseColor;
            
            return Icon(
              LucideIcons.server,
              size: size,
              color: blendedColor,
            );
          }
        },
      ),
    );
  }
}

/// A large, interactive pulsing icon designed for headers.
/// Includes a circular border and a status dot that both reflect the node's state.
class ConsciaHeaderIcon extends StatelessWidget {
  final bool isSleeping;
  final double scale;
  final VoidCallback? onTap;

  const ConsciaHeaderIcon({
    super.key, 
    required this.isSleeping, 
    required this.scale, 
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isSleeping ? ConsciaTheme.warning(context) : ConsciaTheme.accent(context);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48.0 * scale,
              height: 48.0 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor,
                  width: 2.0 * scale,
                ),
              ),
            ),
            PulsingNodeIcon(
              isSleeping: isSleeping, 
              scale: scale, 
              iconSize: 24.0, // Large header size
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12.0 * scale,
                height: 12.0 * scale,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ConsciaTheme.surfaceElevated(context), 
                    width: 2.0 * scale
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
