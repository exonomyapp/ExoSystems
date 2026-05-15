// home_screen.dart — Primary Layout Shell
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '../main.dart';
import '../providers/chat_provider.dart';
import '../providers/toast_provider.dart';
import 'package:exoauth/exoauth.dart';
import '../widgets/modals/new_chat_dialog.dart';
import 'chat_window_screen.dart';
import '../widgets/theme_selector.dart';
import '../widgets/pulsing_icon.dart';
import '../providers/relay_provider.dart';
import '../src/rust/api/messaging.dart';
import '../widgets/modals/peer_list_modal.dart';
import '../widgets/modals/governance_mission_control.dart';
import 'node_management_view.dart';
import '../providers/governance_provider.dart';

enum MainView { chat, nodeManagement }
final activeMainViewProvider = StateProvider<MainView>((ref) => MainView.chat);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    // Dev shortcut: CTRL+P — ping Relay
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
      debugPrint('[DEV] CTRL+P: Pinging Relay...');
      ref.read(identityServiceProvider).pingRelay();
      return true;
    }

    // Dev shortcut: CTRL+S — toggle node sleep
    // This allows the user to manually simulate the node going into 
    // standby mode, which in turn gates the UI's mesh traffic visualization 
    // to ensure total state consistency.
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      final isSleeping = ref.read(nodeSleepProvider);
      ref.read(nodeSleepProvider.notifier).state = !isSleeping;
      debugPrint('[DEV] CTRL+S: Node sleep toggled → ${!isSleeping}');
      return true;
    }

    // Dev shortcut: CTRL+M — toggle sidebar
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyM) {
      final isVisible = ref.read(sidebarVisibleProvider);
      ref.read(sidebarVisibleProvider.notifier).state = !isVisible;
      debugPrint('[DEV] CTRL+M: Sidebar visibility toggled → ${!isVisible}');
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final focusNode = FocusManager.instance.primaryFocus;
      if (focusNode != null && focusNode.context?.widget.runtimeType.toString() == 'EditableText') {
        focusNode.unfocus();
        return true;
      }
      
      final activeView = ref.read(activeMainViewProvider);
      if (activeView == MainView.nodeManagement) {
        ref.read(activeMainViewProvider.notifier).state = MainView.chat;
        return true;
      }
      
      final activeConvoId = ref.read(activeConversationIdProvider);
      if (activeConvoId != null) {
        ref.read(activeConversationIdProvider.notifier).set(null);
        return true;
      }

      final isSigningOut = ref.read(identityProvider).isSigningOut;
      if (!isSigningOut) {
        final scale = ref.read(uiScaleProvider);
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: AppTheme.surface(dialogContext),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Sign Out", style: AppTheme.headingStyle(dialogContext, scale)),
              content: Text("Are you sure you want to sign out?", style: AppTheme.bodyStyle(dialogContext, scale)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text("Cancel", style: TextStyle(color: AppTheme.muted(dialogContext))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error(dialogContext),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    ref.read(identityProvider.notifier).signOut();
                  },
                  child: const Text("Yes, Sign Out"),
                ),
              ],
            );
          },
        );
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isSidebarVisible = ref.watch(sidebarVisibleProvider);
    final activeConvoId = ref.watch(activeConversationIdProvider);
    final conversations = ref.watch(conversationListProvider);
    final scale = ref.watch(uiScaleProvider);
    final activeView = ref.watch(activeMainViewProvider);
    
    final activeConvo = activeConvoId != null 
        ? conversations.cast<Conversation?>().firstWhere((c) => c?.id == activeConvoId, orElse: () => null)
        : null;

    final identity = ref.watch(identityProvider);
    final isSigningOut = identity.isSigningOut;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: IgnorePointer(
        ignoring: isSigningOut,
        child: Opacity(
          opacity: isSigningOut ? 0.5 : 1.0,
          child: ColorFiltered(
            colorFilter: isSigningOut 
              ? const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
              child: LayoutBuilder(
            builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
  
            return Stack(
              children: [
                LayoutGrid(
                  columnSizes: [auto, 1.fr],
                  rowSizes: [1.fr],
                  children: [
                    // Track 0: Sidebar (Exo Sidebar handles its own visibility/width)
                    if (isDesktop)
                      _ExoSidebar(
                        isVisible: isSidebarVisible,
                        scale: scale,
                      ).withGridPlacement(columnStart: 0, rowStart: 0)
                    else
                      const SizedBox.shrink().withGridPlacement(columnStart: 0, rowStart: 0),
                    
                    // Track 1: Content Area
                    Container(
                      child: activeView == MainView.nodeManagement
                          ? const NodeManagementView()
                          : (activeConvo != null 
                              ? ChatWindowScreen(onToggleSidebar: () => ref.read(sidebarVisibleProvider.notifier).state = !isSidebarVisible, isSidebarVisible: isSidebarVisible)
                              : _EmptyStateView(onToggle: () => ref.read(sidebarVisibleProvider.notifier).state = !isSidebarVisible, scale: scale)),
                    ).withGridPlacement(columnStart: 1, rowStart: 0),
                  ],
                ),
                
                if (isDesktop && !isSidebarVisible)
                  Positioned(
                    top: 20.0 * scale,
                    left: 20.0 * scale,
                    child: _SidebarToggle(onTap: () => ref.read(sidebarVisibleProvider.notifier).state = !isSidebarVisible, scale: scale),
                  ),
              ],
            );
          },
        ),
        ),
        ),
      ),
      drawer: !MediaQuery.of(context).size.width.isFinite || MediaQuery.of(context).size.width > 800
          ? null
          : SizedBox(width: 300.0 * scale, child: Drawer(child: SidebarMenu())),
    );
  }
}

class _ExoSidebar extends ConsumerWidget {
  final bool isVisible;
  final double scale;

  const _ExoSidebar({required this.isVisible, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(sidebarWidthProvider);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: isVisible ? (width * scale) : 0,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        border: Border(right: BorderSide(color: AppTheme.border(context))),
      ),
      child: Stack(
        children: [
          SidebarMenu(),
          // Resize handle
          if (isVisible)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newWidth = (width + details.delta.dx / scale).clamp(200.0, 600.0);
                  ref.read(sidebarWidthProvider.notifier).state = newWidth;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    width: 6.0 * scale,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarToggle extends StatelessWidget {
  final VoidCallback onTap;
  final double scale;
  const _SidebarToggle({required this.onTap, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0 * scale),
        child: Container(
          padding: EdgeInsets.all(12.0 * scale),
          decoration: AppTheme.solidDecoration(context, radius: 12.0 * scale),
          child: Icon(LucideIcons.panelLeft, size: 20.0 * scale, color: AppTheme.text(context)),
        ),
      ),
    );
  }
}

class _EmptyStateView extends ConsumerWidget {
  final VoidCallback onToggle;
  final double scale;
  const _EmptyStateView({required this.onToggle, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.mainGradient(context),
        ),
      ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(40.0 * scale),
            child: Container(
              constraints: BoxConstraints(minWidth: 440.0 * scale),
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ExoLogo(scale: scale),
              SizedBox(height: 40.0 * scale),
              Text("Welcome to ExoTalk", style: AppTheme.headingStyle(context, scale).copyWith(fontSize: 36.0 * scale)),
              SizedBox(height: 16.0 * scale),
              Text(
                "A self-autonomous messaging platform built on the Willow protocol. Your identity, your data, your mesh.",
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle(context, scale).copyWith(color: AppTheme.muted(context), height: 1.5),
              ),
              SizedBox(height: 48.0 * scale),
              const _IdentityDashboard(),
              SizedBox(height: 64),
              const _MeshMeter(),
                SizedBox(height: 40.0 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
  }

class _IdentityDashboard extends ConsumerWidget {
  const _IdentityDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final identity = ref.watch(identityProvider);
    final status = ref.watch(relayStatusProvider).value;

    return Column(
      children: [
        _LargeActionButton(
          label: "Talk Securely",
          icon: LucideIcons.plus,
          onPressed: (status?.isConnected ?? false) ? () {
            // Trigger New Chat Modal
          } : null,
          scale: scale,
        ),
        SizedBox(height: 32),
        Container(
          width: 420.0 * scale,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.hover(context),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.fingerprint, size: 16 * scale, color: AppTheme.accent(context)),
              SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: identity.activeDid ?? "Scanning...",
                  child: Text(
                    identity.activeDid != null 
                      ? "Identity: ${identity.activeDid!}"
                      : "Scanning Identities...",
                    style: AppTheme.bodyStyle(context, scale).copyWith(
                      fontSize: 13 * scale,
                      color: AppTheme.muted(context),
                      fontFamily: 'JetBrainsMono',
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (identity.activeDid != null) ...[
                SizedBox(width: 8),
                _CopyButton(
                  text: identity.activeDid!,
                  scale: scale,
                  enabled: status?.isConnected ?? false,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final double scale;
  final bool enabled;
  const _CopyButton({required this.text, required this.scale, this.enabled = true});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          icon: Icon(LucideIcons.copy, size: 16 * widget.scale, color: widget.enabled ? AppTheme.muted(context) : AppTheme.muted(context).withValues(alpha: 0.3)),
          onPressed: !widget.enabled ? null : () async {
            await _animController.forward();
            await _animController.reverse();
            Clipboard.setData(ClipboardData(text: widget.text));
            ref.read(toastProvider.notifier).show("DID copied to clipboard", type: ToastType.success);
          },
          tooltip: "Copy DID",
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 32 * widget.scale, minHeight: 32 * widget.scale),
        ),
      );
    });
  }
}

/// A dual-channel network meter that visualizes inbound (ingress) and outbound
/// (egress) mesh traffic as two independent scrolling bar charts.
///
/// Each lane is gated by its corresponding toggle in the user's profile:
///   - Enabled  → bars pulse with simulated activity
///   - Disabled → bars decay to zero, showing a dashed flatline
///   - Both off → "MESH PAUSED — FLIGHT MODE" header
///
/// Since the Rust FFI does not expose real-time traffic metrics, the bar
/// heights are randomized but _state-gated_: they faithfully represent
/// _whether_ data is flowing, not _how much_.
class _MeshMeter extends ConsumerStatefulWidget {
  const _MeshMeter();

  @override
  ConsumerState<_MeshMeter> createState() => _MeshMeterState();
}

class _MeshMeterState extends ConsumerState<_MeshMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Rolling bar buffers — one per lane
  static const int _barCount = 24;
  final List<double> _ingressBars = List.filled(_barCount, 0.0, growable: true);
  final List<double> _egressBars = List.filled(_barCount, 0.0, growable: true);
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Each tick shifts the bars — 150ms per bar gives a smooth scroll
      duration: const Duration(milliseconds: 150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advanceBars();
          _controller.forward(from: 0.0);
        }
      });
    _controller.forward();
  }

  void _advanceBars() {
    if (!mounted || ref.read(identityProvider).isSigningOut) return;
    
    final user = ref.read(userProfileProvider);
    final status = ref.read(relayStatusProvider).value;
    
    // Mesh activity criteria: toggles are on AND (we are connected OR we have peers OR we just started)
    // We assume activity if toggles are on to show the node is "alive" and searching.
    final bool isIngressActive = user.ingressEnabled;
    final bool isEgressActive = user.egressEnabled;
    
    // If unreachable or sleeping, we force absolute zero (flatline) on the meter.
    // This provides deterministic visual feedback that the mesh is inactive.
    final bool isSleeping = ref.read(nodeSleepProvider);
    final bool canFlow = (status?.isConnected ?? false) && !isSleeping;
    
    // Shift left, append new sample
    _ingressBars.removeAt(0);
    double ingressVal = 0.0;
    if (isIngressActive && canFlow) {
      ingressVal = (status?.activePeers ?? 0) > 0 ? 0.5 + _rng.nextDouble() * 0.5 : 0.15 + _rng.nextDouble() * 0.15;
    }
    _ingressBars.add(ingressVal);

    _egressBars.removeAt(0);
    double egressVal = 0.0;
    if (isEgressActive && canFlow) {
      egressVal = (status?.activePeers ?? 0) > 0 ? 0.5 + _rng.nextDouble() * 0.5 : 0.15 + _rng.nextDouble() * 0.15;
    }
    _egressBars.add(egressVal);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(uiScaleProvider);
    final user = ref.watch(userProfileProvider);
    final status = ref.watch(relayStatusProvider).value;
    final isConnected = status?.isConnected ?? false;
    final peerCount = status?.activePeers ?? 0;
    final hasLiveLink = isConnected || peerCount > 0;
    final isFlightMode = !user.ingressEnabled && !user.egressEnabled;
    final isSleeping = ref.watch(nodeSleepProvider);

    return Column(
      children: [
        // Header - Wrapped in SizedBox to prevent jumping when status items appear
        SizedBox(
          height: 32 * scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSleeping ? "MESH SLEEPING" : (!isConnected
                    ? "UNREACHABLE — MESH PAUSED"
                    : (isFlightMode ? "MESH PAUSED — FLIGHT MODE" : "MESH TRAFFIC")),
                style: AppTheme.bodyStyle(context, scale).copyWith(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0 * scale,
                  color: isSleeping ? AppTheme.warning(context) : (!isConnected || isFlightMode
                      ? AppTheme.error(context)
                      : AppTheme.accent(context)),
                ),
              ),
              if (!isFlightMode && peerCount > 0) ...[
                SizedBox(width: 12 * scale),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showDialog(context: context, builder: (_) => const PeerListModal()),
                    borderRadius: BorderRadius.circular(4 * scale),
                    hoverColor: AppTheme.accent(context).withValues(alpha: 0.1),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.network, size: 14 * scale, color: AppTheme.accent(context)),
                          SizedBox(width: 4 * scale),
                          Text("$peerCount PEERS", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold, fontSize: 9 * scale)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('Governance Mission Control Triggered (Header)');
                        showDialog(context: context, builder: (_) => const GovernanceMissionControlModal());
                      },
                      borderRadius: BorderRadius.circular(4 * scale),
                      hoverColor: AppTheme.accent(context).withValues(alpha: 0.1),
                      child: Padding(
                        padding: EdgeInsets.all(8 * scale),
                        child: Icon(LucideIcons.shieldCheck, size: 18 * scale, color: AppTheme.accent(context)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 20 * scale),
        // Two lanes that wrap naturally
        Wrap(
          spacing: 24 * scale,
          runSpacing: 24 * scale,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _MeshLane(
              label: "INBOUND",
              subtitle: user.ingressEnabled 
                  ? (isSleeping ? "Standby" : (hasLiveLink ? "Receive from mesh" : "Searching..."))
                  : "Paused",
              bars: _ingressBars,
              enabled: user.ingressEnabled && !isSleeping,
              color: AppTheme.meshInbound(context).withValues(alpha: isSleeping ? 0.3 : 1.0),
              animation: _controller,
              scale: scale,
            ),
            _MeshLane(
              label: "OUTBOUND",
              subtitle: user.egressEnabled
                  ? (isSleeping ? "Standby" : (hasLiveLink ? "Broadcast to peers" : "Awaiting peer..."))
                  : "Paused",
              bars: _egressBars,
              enabled: user.egressEnabled && !isSleeping,
              color: AppTheme.meshOutbound(context).withValues(alpha: isSleeping ? 0.3 : 1.0),
              animation: _controller,
              scale: scale,
            ),
          ],
        ),
      ],
    );
  }
}

/// A single lane of the mesh meter: a label, a scrolling bar chart, and a
/// subtitle. When [enabled] is false the bars decay to zero and a dashed
/// flatline is drawn instead.
class _MeshLane extends StatelessWidget {
  final String label;
  final String subtitle;
  final List<double> bars;
  final bool enabled;
  final Color color;
  final Animation<double> animation;
  final double scale;

  const _MeshLane({
    required this.label,
    required this.subtitle,
    required this.bars,
    required this.enabled,
    required this.color,
    required this.animation,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final laneWidth = 160.0 * scale;
    final laneHeight = 40.0 * scale;
    final mutedColor = AppTheme.muted(context);

    return Column(
      children: [
        // Lane label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == "INBOUND" ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              size: 12 * scale,
              color: enabled ? color : mutedColor,
            ),
            SizedBox(width: 4 * scale),
            Text(
              label,
              style: AppTheme.bodyStyle(context, scale).copyWith(
                fontSize: 9 * scale,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5 * scale,
                color: enabled ? color : mutedColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
        // Bar chart canvas
        Container(
          width: laneWidth,
          height: laneHeight,
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(6 * scale),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.3)
                  : AppTheme.border(context),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5 * scale),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MeshLanePainter(
                    bars: bars,
                    enabled: enabled,
                    activeColor: color,
                    mutedColor: AppTheme.border(context),
                    t: animation.value,
                  ),
                  size: Size(laneWidth, laneHeight),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 6 * scale),
        // Subtitle
        Text(
          enabled ? subtitle : (label == "INBOUND" ? "Paused" : "Paused"),
          style: AppTheme.bodyStyle(context, scale).copyWith(
            fontSize: 9 * scale,
            color: enabled ? color.withValues(alpha: 0.6) : mutedColor,
          ),
        ),
      ],
    );
  }
}

/// Paints a scrolling bar chart for one meter lane.
///
/// When [enabled] is true, bars are drawn as filled rounded rectangles
/// that rise from the bottom. When disabled, a dashed horizontal
/// flatline is drawn at the vertical center.
class _MeshLanePainter extends CustomPainter {
  final List<double> bars;
  final bool enabled;
  final Color activeColor;
  final Color mutedColor;
  /// The [t] parameter represents the normalized progress (0.0 to 1.0) of the
  /// current animation cycle. To achieve smooth scrolling, we subtract [t]
  /// from the horizontal index [i]. This causes each bar to move one full
  /// slot to the left over the course of the animation. At t=1, the source
  /// list is shifted and t resets to 0, creating a seamless loop.
  final double t; // 0..1 animation progress for smooth scrolling

  _MeshLanePainter({
    required this.bars,
    required this.enabled,
    required this.activeColor,
    required this.mutedColor,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int count = bars.length;
    final double gap = 2.0;
    final double barWidth = (size.width - (count - 1) * gap) / count;
    final double maxBarHeight = size.height - 4.0; // 2px padding top+bottom
    final double baseY = size.height - 2.0;

    if (!enabled) {
      // Draw dashed flatline
      final paint = Paint()
        ..color = mutedColor
        ..strokeWidth = 1.0;
      final double midY = size.height / 2;
      const double dashWidth = 6.0;
      const double dashGap = 4.0;
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, midY),
          Offset(math.min(x + dashWidth, size.width), midY),
          paint,
        );
        x += dashWidth + dashGap;
      }
      return;
    }

    // Draw active bars
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double value = bars[i].clamp(0.0, 1.0);
      if (value <= 0.01) continue;
      
      // Force a minimum height so small blips are always visible
      final double barHeight = math.max(3.0, value * maxBarHeight);

      // Fade older bars (left = older), keep them brighter to guarantee visibility
      final double ageFactor = 0.6 + 0.4 * (i / (count - 1));
      paint.color = activeColor.withValues(alpha: ageFactor);

      // Smooth horizontal scroll: shift bars by t pixels
      final double x = (i - t) * (barWidth + gap);
      final RRect rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - barHeight, barWidth, barHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rr, paint);
    }

    // Draw a subtle baseline
    final basePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, baseY), Offset(size.width, baseY), basePaint);
  }

  @override
  bool shouldRepaint(covariant _MeshLanePainter oldDelegate) => true;
}

class _ExoLogo extends StatelessWidget {
  final double scale;
  const _ExoLogo({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140.0 * scale,
          height: 140.0 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppTheme.accentDark(context), AppTheme.background(context)],
            ),
          ),
        ),
        Icon(LucideIcons.shield, size: 80.0 * scale, color: AppTheme.accent(context)),
        Positioned(
          bottom: 20.0 * scale,
          right: 20.0 * scale,
          child: Container(
            padding: EdgeInsets.all(8.0 * scale),
            decoration: BoxDecoration(color: AppTheme.background(context), shape: BoxShape.circle, border: Border.all(color: AppTheme.accent(context))),
            child: Icon(LucideIcons.lock, size: 24.0 * scale, color: AppTheme.accent(context)),
          ),
        ),
      ],
    );
  }
}


class _LargeActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double scale;
  const _LargeActionButton({required this.label, this.icon, required this.onPressed, required this.scale});

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? AppTheme.accent(context) : AppTheme.muted(context).withValues(alpha: 0.1),
        foregroundColor: isEnabled ? Colors.white : AppTheme.muted(context).withValues(alpha: 0.5),
        padding: EdgeInsets.symmetric(horizontal: 40.0 * scale, vertical: 20.0 * scale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0 * scale)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20 * scale, color: isEnabled ? Colors.white : AppTheme.muted(context).withValues(alpha: 0.5)),
            SizedBox(width: 12),
          ],
          Text(label, style: AppTheme.subHeadingStyle(context, scale).copyWith(color: isEnabled ? Colors.white : AppTheme.muted(context).withValues(alpha: 0.5), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class SidebarMenu extends ConsumerStatefulWidget {
  const SidebarMenu({super.key});
  @override
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(filteredConversationsProvider);
    final user = ref.watch(userProfileProvider);
    final activeConvoId = ref.watch(activeConversationIdProvider);
    final scale = ref.watch(uiScaleProvider);

    return Column(
      children: [
        _SidebarHeader(user: user, scale: scale),
        _SidebarSearch(scale: scale),
        Expanded(
          child: _SidebarContent(
            conversations: conversations,
            activeConvoId: activeConvoId,
            scale: scale,
          ),
        ),
        _SidebarFooter(scale: scale),
      ],
    );
  }
}

class _SidebarHeader extends ConsumerWidget {
  final UserProfile user;
  final double scale;
  const _SidebarHeader({required this.user, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityState = ref.watch(identityProvider);
    final isSigningOut = identityState.isSigningOut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppTheme.headerPaddingVertical(scale)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.headerPaddingHorizontal(scale)),
          child: Row(
            children: [
              PopupMenuButton<String>(
                enabled: !isSigningOut,
                tooltip: "Switch Persona",
                offset: Offset(0, 50.0 * scale),
                color: AppTheme.surface(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0 * scale), side: BorderSide(color: AppTheme.border(context))),
                onSelected: (value) {
                  if (value == "add") {
                    showDialog(context: context, builder: (_) => AccountManagerModal());
                  } else if (value == "signout") {
                    ref.read(identityProvider.notifier).signOut();
                  } else {
                    ref.read(identityProvider.notifier).switchIdentity(value);
                  }
                },
                itemBuilder: (context) => [
                  ...identityState.knownIdentities.map((identity) => PopupMenuItem<String>(
                    value: identity.did,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12.0 * scale,
                          backgroundColor: identity.did == identityState.activeDid ? AppTheme.accent(context) : AppTheme.border(context),
                          child: Text(identity.displayName.isNotEmpty ? identity.displayName[0] : '?', style: TextStyle(fontSize: 10.0 * scale, color: Colors.white)),
                        ),
                        SizedBox(width: 12.0 * scale),
                        Expanded(child: Text(identity.displayName, style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: identity.did == identityState.activeDid ? FontWeight.bold : FontWeight.normal))),
                        if (identity.did == identityState.activeDid) Icon(LucideIcons.check, size: 14.0 * scale, color: AppTheme.accent(context)),
                      ],
                    ),
                  )),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: "add",
                    child: Row(
                      children: [
                        Icon(LucideIcons.userPlus, size: 16.0 * scale, color: AppTheme.accent(context)),
                        SizedBox(width: 12.0 * scale),
                        Text("Add Profile", style: AppTheme.bodyStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: "signout",
                    child: Row(
                      children: [
                        Icon(LucideIcons.logOut, size: 16.0 * scale, color: AppTheme.error(context)),
                        SizedBox(width: 12.0 * scale),
                        Text("Sign Out", style: AppTheme.bodyStyle(context, scale).copyWith(color: AppTheme.error(context))),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 22.0 * scale,
                  backgroundColor: AppTheme.border(context),
                  backgroundImage: (!isSigningOut && user.avatarBytes != null) ? MemoryImage(user.avatarBytes!) : null,
                  child: (isSigningOut || user.avatarBytes == null) ? Icon(LucideIcons.user, size: 20.0 * scale, color: AppTheme.muted(context)) : null,
                ),
              ),
              SizedBox(width: 12.0 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSigningOut ? "Signing out..." : user.name, style: AppTheme.subHeadingStyle(context, scale), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(isSigningOut ? "Closing session" : user.did, style: AppTheme.captionStyle(context, scale).copyWith(fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.doorOpen, size: 18.0 * scale, color: isSigningOut ? AppTheme.muted(context) : AppTheme.error(context)),
                tooltip: "Exit Workspace",
                onPressed: isSigningOut ? null : () => ref.read(identityProvider.notifier).signOut(),
              ),
              IconButton(
                icon: Icon(LucideIcons.panelLeft, size: 18.0 * scale, color: AppTheme.muted(context)),
                tooltip: "Collapse Sidebar",
                onPressed: isSigningOut ? null : () => ref.read(sidebarVisibleProvider.notifier).state = false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarSearch extends ConsumerWidget {
  final double scale;
  const _SidebarSearch({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.headerPaddingHorizontal(scale), vertical: 10.0 * scale),
      child: TextField(
        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        decoration: InputDecoration(
          hintText: "Search connections...",
          hintStyle: AppTheme.captionStyle(context, scale),
          prefixIcon: Icon(LucideIcons.search, size: 16.0 * scale, color: AppTheme.muted(context)),
          filled: true,
          fillColor: AppTheme.background(context),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0 * scale), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _SidebarContent extends ConsumerStatefulWidget {
  final List<Conversation> conversations;
  final String? activeConvoId;
  final double scale;

  const _SidebarContent({required this.conversations, required this.activeConvoId, required this.scale});

  @override
  ConsumerState<_SidebarContent> createState() => _SidebarContentState();
}

class _SidebarContentState extends ConsumerState<_SidebarContent> {
  bool _nodesExpanded = true;

  void _showAddNodeDialog(BuildContext context) {
    final controller = TextEditingController();
    final scale = widget.scale;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0 * scale),
          side: BorderSide(color: AppTheme.border(context)),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.serverCog, size: 20.0 * scale, color: AppTheme.accent(context)),
            SizedBox(width: 12.0 * scale),
            Text("Add Relay Node", style: AppTheme.subHeadingStyle(context, scale)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter the Node ID of the relay instance to associate.", style: AppTheme.captionStyle(context, scale)),
            SizedBox(height: 16.0 * scale),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTheme.bodyStyle(context, scale).copyWith(fontFamily: 'monospace'),
              decoration: AppTheme.inputDecoration(context, "Node ID (e.g. did:peer:...)", scale),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: AppTheme.muted(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0 * scale)),
            ),
            onPressed: () async {
              final nodeId = controller.text.trim();
              if (nodeId.isNotEmpty) {
                await ref.read(associatedRelayProvider.notifier).associateNode(nodeId);
                ref.invalidate(peerListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Add Node"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final peersAsync = ref.watch(peerListProvider);
    final selectedNodeId = ref.watch(selectedNodeIdProvider);
    final governance = ref.watch(governanceProvider);
    final pendingRequests = governance.pendingRequests;

    final isSleeping = ref.watch(nodeSleepProvider);

    return Column(
      children: [
        if (pendingRequests.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.headerPaddingHorizontal(scale)),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Row(
                children: [
                  Text("Requests", style: AppTheme.subHeadingStyle(context, scale).copyWith(color: AppTheme.accent(context))),
                  SizedBox(width: 8.0 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.0 * scale, vertical: 2.0 * scale),
                    decoration: BoxDecoration(color: AppTheme.accent(context), borderRadius: BorderRadius.circular(10.0 * scale)),
                    child: Text("${pendingRequests.length}", style: AppTheme.captionStyle(context, scale).copyWith(color: Colors.white, fontSize: 10.0 * scale, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              collapsedIconColor: AppTheme.muted(context),
              iconColor: AppTheme.accent(context),
              children: pendingRequests.map((reqId) {
                final isSelected = reqId == selectedNodeId;
                return Container(
                  margin: EdgeInsets.only(bottom: 2.0 * scale),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.selection(context) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0 * scale),
                  ),
                  child: ListTile(
                    onTap: () {
                      ref.read(selectedNodeIdProvider.notifier).state = reqId;
                      ref.read(activeMainViewProvider.notifier).state = MainView.nodeManagement;
                    },
                    leading: Icon(LucideIcons.userPlus, size: 16.0 * scale, color: AppTheme.accent(context)),
                    title: Text(
                      reqId,
                      style: AppTheme.captionStyle(context, scale).copyWith(
                        fontFamily: 'monospace',
                        color: isSelected ? AppTheme.text(context) : AppTheme.muted(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(LucideIcons.chevronRight, size: 14.0 * scale, color: AppTheme.muted(context)),
                    dense: true,
                  ),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.headerPaddingHorizontal(scale)),
            children: [
              ExpansionTile(
                initiallyExpanded: true,
                title: Text("Chats", style: AppTheme.subHeadingStyle(context, scale)),
                collapsedIconColor: AppTheme.muted(context),
                iconColor: AppTheme.accent(context),
                // Use default trailing (Flutter animates it automatically)
                children: [
                  _ConversationList(conversations: widget.conversations, activeConvoId: widget.activeConvoId, scale: scale),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.headerPaddingHorizontal(scale)),
          child: ExpansionTile(
          initiallyExpanded: true,
          onExpansionChanged: (expanded) => setState(() => _nodesExpanded = expanded),
          title: Text("Relay Nodes", style: AppTheme.subHeadingStyle(context, scale)),
          collapsedIconColor: AppTheme.muted(context),
          iconColor: AppTheme.accent(context),
          // Custom trailing: animated chevron + add icon
          // We rebuild the trailing ourselves so the + icon stays clickable
          // and the chevron correctly reflects expansion state.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: "Add Node",
                child: InkWell(
                  borderRadius: BorderRadius.circular(6.0 * scale),
                  onTap: () => _showAddNodeDialog(context),
                  child: Padding(
                    padding: EdgeInsets.all(4.0 * scale),
                    child: Icon(LucideIcons.plus, size: 16.0 * scale, color: AppTheme.accent(context)),
                  ),
                ),
              ),
              SizedBox(width: 4.0 * scale),
              AnimatedRotation(
                turns: _nodesExpanded ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(LucideIcons.chevronDown, size: 16.0 * scale, color: AppTheme.muted(context)),
              ),
            ],
          ),
          children: [
            peersAsync.when(
              loading: () => Padding(
                padding: EdgeInsets.all(16.0 * scale),
                child: Center(child: SizedBox(width: 16.0 * scale, height: 16.0 * scale, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent(context)))),
              ),
              error: (err, stack) => Padding(
                padding: EdgeInsets.all(16.0 * scale),
                child: Text("Could not load nodes.", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.error(context))),
              ),
              data: (peers) {
                if (peers.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
                    child: Text("No nodes in roster.", style: AppTheme.captionStyle(context, scale)),
                  );
                }
                return Column(
                  children: peers.map((peer) {
                    final isSelected = peer.nodeId == selectedNodeId;
                    return Container(
                      margin: EdgeInsets.only(bottom: 2.0 * scale),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.selection(context) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.0 * scale),
                      ),
                      child: ListTile(
                        onTap: () {
                          ref.read(selectedNodeIdProvider.notifier).state = peer.nodeId;
                          ref.read(activeMainViewProvider.notifier).state = MainView.nodeManagement;
                        },
                        leading: PulsingNodeIcon(isSleeping: isSleeping, scale: scale),
                        title: Text(
                          peer.nodeId,
                          style: AppTheme.captionStyle(context, scale).copyWith(
                            fontFamily: 'monospace',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.text(context) : AppTheme.muted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
                        hoverColor: AppTheme.hover(context),
                        dense: true,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
          ),
        ),
      ],
    );
  }
}



class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final String? activeConvoId;
  final double scale;

  const _ConversationList({required this.conversations, required this.activeConvoId, required this.scale});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final convo = conversations[index];
        final isActive = convo.id == activeConvoId;
        return _ConversationTile(convo: convo, isActive: isActive, scale: scale);
      },
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation convo;
  final bool isActive;
  final double scale;

  const _ConversationTile({required this.convo, required this.isActive, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.0 * scale),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.selection(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0 * scale),
      ),
      child: ListTile(
        onTap: () {
          ref.read(activeConversationIdProvider.notifier).set(convo.id);
          ref.read(activeMainViewProvider.notifier).state = MainView.chat;
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
        leading: CircleAvatar(
          radius: 18.0 * scale,
          backgroundColor: AppTheme.border(context),
          child: Text(convo.title[0].toUpperCase(), style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.text(context), fontWeight: FontWeight.bold)),
        ),
        title: Text(convo.title, style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text("Secure channel active", style: AppTheme.captionStyle(context, scale)),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  final double scale;
  const _SidebarFooter({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityState = ref.watch(identityProvider);
    final isSigningOut = identityState.isSigningOut;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0 * scale, vertical: 20.0 * scale),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border(context)))),
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSigningOut ? AppTheme.muted(context).withValues(alpha: 0.1) : AppTheme.selection(context),
              foregroundColor: isSigningOut ? AppTheme.muted(context).withValues(alpha: 0.5) : AppTheme.text(context),
              minimumSize: Size(double.infinity, 44.0 * scale),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0 * scale)),
              elevation: 0,
            ),
            onPressed: isSigningOut ? null : () => showDialog(context: context, builder: (_) => NewChatDialogModal()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.plus, size: 16.0 * scale),
                SizedBox(width: 8.0 * scale),
                Flexible(child: Text("Talk Securely", style: AppTheme.bodyStyle(context, scale).copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          _StatusFooter(scale: scale),
          SizedBox(height: 16.0 * scale),
          const _SidebarBottomControls(),
        ],
      ),
    );
  }
}

class _SidebarBottomControls extends ConsumerWidget {
  const _SidebarBottomControls();

  Future<void> _toggleFlightMode(WidgetRef ref, UserProfile user) async {
    final bool anySyncActive = user.ingressEnabled || user.egressEnabled;
    final targetEnable = !anySyncActive;

    await setIngressEnabled(enabled: targetEnable);
    await setEgressEnabled(enabled: targetEnable);
    
    await ref.read(userProfileProvider.notifier).refreshFromVault();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final user = ref.watch(userProfileProvider);
    final identityState = ref.watch(identityProvider);
    final isSigningOut = identityState.isSigningOut;
    final bool isFlightMode = !user.ingressEnabled && !user.egressEnabled;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0 * scale, horizontal: 8.0 * scale),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border(context).withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isFlightMode ? LucideIcons.planeLanding : LucideIcons.plane, size: 18.0 * scale),
                color: isFlightMode ? AppTheme.error(context) : AppTheme.muted(context),
                tooltip: isFlightMode ? "Mesh Paused (Flight Mode)" : "Mesh Active",
                onPressed: isSigningOut ? null : () => _toggleFlightMode(ref, user),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.0 * scale, minHeight: 32.0 * scale),
              ),
              IconButton(
                icon: Icon(LucideIcons.settings, size: 18.0 * scale, color: AppTheme.muted(context)),
                tooltip: "Settings",
                onPressed: isSigningOut ? null : () => showDialog(context: context, builder: (_) => AccountManagerModal()),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.0 * scale, minHeight: 32.0 * scale),
              ),
            ],
          ),
          ThemeTristateToggle(scale: scale),
        ],
      ),
    );
  }
}


class _StatusFooter extends ConsumerWidget {
  final double scale;
  const _StatusFooter({required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(relayStatusProvider);
    final isSleeping = ref.watch(nodeSleepProvider);
    return statusAsync.when(
      data: (status) {
        final text = isSleeping ? "Relay Asleep" : (status.isConnected ? "Relay Active" : "Mesh Disconnected");
        final color = isSleeping ? AppTheme.warning(context) : (status.isConnected ? AppTheme.accent(context) : AppTheme.error(context));
        
        return InkWell(
          onTap: () async {
            ref.read(toastProvider.notifier).show("Dialing Relay node...", type: ToastType.info);
            await ref.read(identityServiceProvider).pingRelay();
          },
          borderRadius: BorderRadius.circular(8.0 * scale),
          hoverColor: AppTheme.selection(context),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0 * scale, horizontal: 8.0 * scale),
            child: Row(
              children: [
                Container(width: 8.0 * scale, height: 8.0 * scale, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                SizedBox(width: 8.0 * scale),
                Flexible(child: Text(text, style: AppTheme.captionStyle(context, scale), overflow: TextOverflow.ellipsis)),
                if (status.activePeers > 0) ...[
                  SizedBox(width: 12.0 * scale),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showDialog(context: context, builder: (_) => const PeerListModal()),
                      borderRadius: BorderRadius.circular(4.0 * scale),
                      hoverColor: AppTheme.accent(context).withValues(alpha: 0.1),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.network, size: 14.0 * scale, color: AppTheme.accent(context)),
                            SizedBox(width: 4.0 * scale),
                            Text("${status.activePeers}", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.accent(context), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0 * scale),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          debugPrint('Governance Mission Control Triggered (Footer)');
                          showDialog(context: context, builder: (_) => const GovernanceMissionControlModal());
                        },
                        borderRadius: BorderRadius.circular(4 * scale),
                        hoverColor: AppTheme.accent(context).withValues(alpha: 0.1),
                        child: Padding(
                          padding: EdgeInsets.all(8 * scale),
                          child: Icon(LucideIcons.shieldCheck, size: 18.0 * scale, color: AppTheme.accent(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => LinearProgressIndicator(),
      error: (_, _) => Text("Status Error", style: AppTheme.captionStyle(context, scale).copyWith(color: AppTheme.error(context))),
    );
  }
}
