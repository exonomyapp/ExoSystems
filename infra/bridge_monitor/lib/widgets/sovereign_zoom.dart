import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🧠 Educational Context: SovereignZoom
/// This widget implements a modular zooming dynamic that can be implemented
/// uniformly in every Exosystem app. It uses a Transform.scale approach
/// anchored at the Top-Left to ensure deterministic layout scaling.
class SovereignZoom extends StatefulWidget {
  final Widget child;
  const SovereignZoom({super.key, required this.child});

  /// Access the zoom state from descendants if needed.
  static double scaleOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_SovereignZoomState>();
    return state?._scale ?? 1.0;
  }

  @override
  State<SovereignZoom> createState() => _SovereignZoomState();
}

class _SovereignZoomState extends State<SovereignZoom> {
  double _scale = 1.0;
  static const String _zoomKey = 'sovereign_zoom_factor';

  @override
  void initState() {
    super.initState();
    _loadZoom();
  }

  Future<void> _loadZoom() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scale = prefs.getDouble(_zoomKey) ?? 1.0;
    });
  }

  Future<void> _saveZoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_zoomKey, _scale);
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale + 0.05).clamp(0.5, 3.0);
    });
    _saveZoom();
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale - 0.05).clamp(0.5, 3.0);
    });
    _saveZoom();
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
    });
    _saveZoom();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Pattern: CallbackShortcuts provides a clean, declarative way to 
    // bind keys to logic without a FocusNode mess.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.equal, control: true): _zoomIn,
        const SingleActivator(LogicalKeyboardKey.minus, control: true): _zoomOut,
        const SingleActivator(LogicalKeyboardKey.digit0, control: true): _resetZoom,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // We must ensure the child thinks it has more space when scaling down,
          // and less space when scaling up, to keep the layout consistent.
          return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: constraints.maxWidth / _scale,
            maxWidth: constraints.maxWidth / _scale,
            minHeight: constraints.maxHeight / _scale,
            maxHeight: constraints.maxHeight / _scale,
            child: Transform.scale(
              scale: _scale,
              alignment: Alignment.topLeft,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
