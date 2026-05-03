import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'widgets/sovereign_zoom.dart';

void main() {
  runApp(const ExoTechBridgeApp());
}

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<bool> debugPaintNotifier = ValueNotifier(false);
final ValueNotifier<int> buildCountNotifier = ValueNotifier(0);
final ValueNotifier<bool> agentModeNotifier = ValueNotifier(false);
final ValueNotifier<int> currentIntervalNotifier = ValueNotifier(1000);
final ValueNotifier<String?> resetFlashNotifier = ValueNotifier(null);
final ValueNotifier<List<String>> topCpuNotifier = ValueNotifier([]);
final ValueNotifier<String> memRssNotifier = ValueNotifier("0 MB");

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🧠 Educational Context: Modular Zoom
    // We wrap the entire app in SovereignZoom to ensure all elements,
    // including the header, scale uniformly as per ExoTalk's design.
    return SovereignZoom(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'ExoTech Bridge',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A0A),
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C9A7), brightness: Brightness.dark),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            ),
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFD1D3D8),
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C9A7), brightness: Brightness.light),
              textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
            ),
            home: const BridgeMonitorScreen(),
          );
        },
      ),
    );
  }
}

class BridgeMonitorScreen extends StatefulWidget {
  const BridgeMonitorScreen({super.key});

  @override
  State<BridgeMonitorScreen> createState() => _BridgeMonitorScreenState();
}

class _BridgeMonitorScreenState extends State<BridgeMonitorScreen> {
  bool _isGridView = true;
  String _localHost = "DISCOVERING...";
  late List<BridgeNode> _nodes;
  String? _lastKey;
  Timer? _refreshTimer;
  bool _isScanning = false;
  int _consecutiveSteadyStates = 0;
  File? _sessionLogFile;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  _BridgeMonitorScreenState() {
    _nodes = [
      BridgeNode(id: "signaling-1", name: "Signaling Relay", machine: "EXONOMY", role: "WebRTC Handshake Bridge", port: 8080, icon: Icons.hub_outlined, startCmd: "systemctl --user start exotalk-signaling", stopCmd: "systemctl --user stop exotalk-signaling"),
      BridgeNode(id: "conscia-1", name: "Conscia Beacon", machine: "EXONOMY", role: "P2P Mesh Node (Sovereign)", port: 3000, icon: Icons.radar_outlined, startCmd: "nohup /home/exocrat/code/exotalk/exotalk_engine/target/release/conscia daemon > /home/exocrat/conscia.log 2>&1 &", stopCmd: "pkill -f 'target/release/conscia'"),
      BridgeNode(id: "proxy-1", name: "Public Proxy", machine: "ZROK INFRA", role: "External Gateway (exotalk.tech)", port: 0, icon: Icons.public_outlined, startCmd: "systemctl --user start exotalk-zrok", stopCmd: "systemctl --user stop exotalk-zrok"),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initStorage();
    _loadState().then((_) {
      setState(() { _localHost = Platform.localHostname.toUpperCase(); });
      _performScan();
    });
    _startPolling(const Duration(seconds: 1));
  }

  void _startPolling(Duration interval) {
    _refreshTimer?.cancel();
    currentIntervalNotifier.value = interval.inMilliseconds;
    _refreshTimer = Timer.periodic(interval, (_) => _performScan());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initStorage() async {
    final dir = Directory('logs');
    if (!await dir.exists()) await dir.create(recursive: true);
    _sessionLogFile = File('logs/session.log');
    if (!await _sessionLogFile!.exists()) await _sessionLogFile!.create();
  }

  Future<void> _saveState() async {
    try {
      final config = {
        'nodes': _nodes.map((n) => {'id': n.id, 'intendedUp': n.isUp, 'isSleeping': n.isSleeping}).toList(),
        'theme': themeModeNotifier.value.index,
        'isGridView': _isGridView,
      };
      await File('/home/exocrat/.exotech_bridge_config.json').writeAsString(jsonEncode(config));
    } catch (_) {}
  }

  Future<void> _loadState() async {
    try {
      final file = File('/home/exocrat/.exotech_bridge_config.json');
      if (await file.exists()) {
        final config = jsonDecode(await file.readAsString());
        final themeIdx = config['theme'] as int?;
        if (themeIdx != null) themeModeNotifier.value = ThemeMode.values[themeIdx];
        setState(() { _isGridView = config['isGridView'] ?? true; });
        final pNodes = config['nodes'] as List?;
        if (pNodes != null) {
          for (var pNode in pNodes) {
            final node = _nodes.firstWhere((n) => n.id == pNode['id']);
            node.isSleeping = pNode['isSleeping'] ?? false;
            node.isUp = pNode['intendedUp'] ?? false;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _performScan() async {
    if (_isScanning) return;
    _isScanning = true;

    // 🧠 Educational Context: Telemetry Collection
    // We use standard OS utilities (systemctl, pgrep, ps, free) to gather 
    // real-time health data for the mesh nodes and host resources.
    for (var node in _nodes) {
      bool changed = false;
      if (node.id.startsWith("signaling")) {
        final res = await Process.run('systemctl', ['--user', 'is-active', 'exotalk-signaling']);
        bool newState = res.exitCode == 0;
        if (newState != node.isUp) changed = true;
        node.isUp = newState;
      } else if (node.id.startsWith("conscia")) {
        if (node.isSleeping) { node.isUp = false; continue; }
        final res = await Process.run('pgrep', ['-f', 'conscia']);
        bool newState = res.exitCode == 0;
        if (newState != node.isUp) changed = true;
        node.isUp = newState;
      } else if (node.id.startsWith("proxy")) {
        final res = await Process.run('systemctl', ['--user', 'is-active', 'exotalk-zrok']);
        bool newState = res.exitCode == 0;
        if (newState != node.isUp) changed = true;
        node.isUp = newState;
      }
      if (changed) _consecutiveSteadyStates = 0;
    }

    // Update Resource Telemetry for Agent HUD
    try {
      final cpuRes = await Process.run('ps', ['-eo', 'pcpu,comm', '--sort=-pcpu']);
      final lines = cpuRes.stdout.toString().split('\n').where((l) => l.trim().isNotEmpty).skip(1).take(5).toList();
      topCpuNotifier.value = lines.map((l) => l.trim()).toList();

      final memRes = await Process.run('free', ['-m']);
      final memLines = memRes.stdout.toString().split('\n');
      if (memLines.length > 1) {
        final parts = memLines[1].split(RegExp(r'\s+'));
        if (parts.length > 2) memRssNotifier.value = "${parts[2]}MB / ${parts[1]}MB";
      }
    } catch (_) {}

    _consecutiveSteadyStates++;
    _isScanning = false;
  }

  void _handleShortcut(String key) {
    if (key == 't') {
      final current = themeModeNotifier.value;
      themeModeNotifier.value = current == ThemeMode.dark ? ThemeMode.light : (current == ThemeMode.light ? ThemeMode.system : ThemeMode.dark);
      _saveState();
    } else if (key == 'v') {
      setState(() => _isGridView = !_isGridView);
      _saveState();
    } else if (key == 'r') {
      _performScan();
    } else if (key == 'h') {
      agentModeNotifier.value = !agentModeNotifier.value;
    } else if (key == 'd') {
      debugPaintNotifier.value = !debugPaintNotifier.value;
    } else if (key == 's') {
      final newInterval = currentIntervalNotifier.value == 1000 ? 500 : 1000;
      _startPolling(Duration(milliseconds: newInterval));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) { if (event is KeyDownEvent) _handleShortcut(event.logicalKey.keyLabel.toLowerCase()); },
      child: ValueListenableBuilder<bool>(
        valueListenable: debugPaintNotifier,
        builder: (context, debugPaint, child) {
          // 💡 Pattern: Repaint Rainbow
          // We use the global debugRepaintRainbowEnabled to visualize 
          // rendering activity during KDVV audits.
          debugRepaintRainbowEnabled = debugPaint;
          return child!;
        },
        child: Scaffold(
          body: Column(
            children: [
              _buildPremiumHeader(isDark),
              Expanded(child: _isGridView ? _buildGrid(isDark) : _buildList(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFAEB2B8),
      ),
      child: Row(
        children: [
          Image.asset(isDark ? 'assets/exotalk_pappus_realistic.png' : 'assets/exotalk_pappus_color.png', width: 96, height: 96),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("EXOTECH BRIDGE", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 28, color: isDark ? Colors.white : Colors.black87)),
              Text("ACTIVE TELEMETRY | NODE: $_localHost | v1.1.2-FINAL", style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          // 🧠 Educational Context: Centered HUD
          // Relocating HUD to the center reduces eye travel and ensures 
          // critical telemetry is prominent without crowding the title.
          _buildCenteredHUD(isDark),
          const Spacer(),
          _buildThemeSwitcher(isDark),
          const SizedBox(width: 16),
          _buildViewToggle(isDark),
        ],
      ),
    );
  }

  Widget _buildCenteredHUD(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: agentModeNotifier,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: currentIntervalNotifier,
                  builder: (context, interval, _) => Text(
                    "AGENT MODE | INTERVAL: ${interval}ms | STEADY: $_consecutiveSteadyStates",
                    style: GoogleFonts.firaCode(fontSize: 9, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                ValueListenableBuilder<List<String>>(
                  valueListenable: topCpuNotifier,
                  builder: (context, top, _) => Text(
                    top.take(1).join(", "),
                    style: GoogleFonts.firaCode(fontSize: 8, color: Colors.orange.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<String>(
              valueListenable: memRssNotifier,
              builder: (context, rss, _) => Text(
                "MEM: $rss",
                style: GoogleFonts.firaCode(fontSize: 9, color: const Color(0xFF00C9A7)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeSwitcher(bool isDark) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, current, _) {
        return CupertinoSlidingSegmentedControl<ThemeMode>(
          groupValue: current,
          children: {
            ThemeMode.light: Icon(Icons.light_mode, size: 14, color: current == ThemeMode.light ? const Color(0xFF00C9A7) : Colors.grey),
            ThemeMode.system: Icon(Icons.settings_brightness, size: 14, color: current == ThemeMode.system ? const Color(0xFF00C9A7) : Colors.grey),
            ThemeMode.dark: Icon(Icons.dark_mode, size: 14, color: current == ThemeMode.dark ? const Color(0xFF00C9A7) : Colors.grey),
          },
          onValueChanged: (v) { if (v != null) themeModeNotifier.value = v; _saveState(); },
        );
      },
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: _isGridView,
      children: {
        true: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.grid_view, size: 16, color: _isGridView ? const Color(0xFF00C9A7) : Colors.grey)),
        false: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.view_list, size: 16, color: !_isGridView ? const Color(0xFF00C9A7) : Colors.grey)),
      },
      onValueChanged: (v) { if (v != null) setState(() { _isGridView = v; }); _saveState(); },
    );
  }

  Widget _buildGrid(bool isDark) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(48),
        child: Align(
          alignment: Alignment.topLeft,
          // 🧠 Educational Context: flutter_layout_grid
          // Using LayoutGrid ensures a deterministic, CSS-like grid that 
          // handles dynamic scaling and 2D alignment far better than Wrap.
          child: LayoutGrid(
            columnSizes: repeat(3, [1.fr]), // Default 3 columns
            rowSizes: [auto, auto],
            rowGap: 32, columnGap: 32,
            children: _nodes.map((node) => _buildNodeCard(node, isDark)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _nodes.map((node) => _buildNodeRow(node, isDark)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCard(BridgeNode node, bool isDark) {
    final statusColor = node.isSleeping ? Colors.orange : (node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F));
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minWidth: 280), height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // 🧠 Educational Context: Surgical Rendering
              // We wrap the indicator in a RepaintBoundary to isolate 
              // the pulsing animation from the rest of the card.
              RepaintBoundary(child: _StatusIndicator(isUp: node.isUp, isSleeping: node.isSleeping)), 
              const SizedBox(width: 12), 
              Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
              const Spacer(), 
              Icon(node.icon, color: statusColor.withOpacity(0.5), size: 16),
            ]),
            const SizedBox(height: 8),
            Text(node.role, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
               node.id == "conscia-1" 
                 ? CupertinoSlidingSegmentedControl<int>(
                     groupValue: node.isSleeping ? 1 : (node.isUp ? 2 : 0),
                     children: {0: const Icon(Icons.power_off, size: 14), 1: const Icon(Icons.bedtime, size: 14), 2: const Icon(Icons.power, size: 14)},
                     onValueChanged: (v) { if (v != null) _cycleConscia(node, v); },
                   )
                 : CupertinoSwitch(value: node.isUp, activeColor: const Color(0xFF00C9A7), onChanged: (v) => _toggleService(node)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeRow(BridgeNode node, bool isDark) {
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1C1C1E) : Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(node.icon, color: statusColor), const SizedBox(width: 24),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(node.role, style: const TextStyle(fontSize: 12))])),
            _StatusIndicator(isUp: node.isUp, isSleeping: node.isSleeping),
          ],
        ),
      ),
    );
  }

  void _toggleService(BridgeNode node) async {
    setState(() { node.isUp = !node.isUp; });
    if (node.isUp) await Process.run('bash', ['-c', node.startCmd]);
    else await Process.run('bash', ['-c', node.stopCmd]);
    _saveState();
  }

  void _cycleConscia(BridgeNode node, int state) async {
    await Process.run('bash', ['-c', "pkill -f conscia"]);
    if (state == 0) setState(() { node.isSleeping = false; node.isUp = false; });
    else if (state == 1) setState(() { node.isSleeping = true; node.isUp = false; });
    else if (state == 2) { setState(() { node.isSleeping = false; node.isUp = true; }); await Process.run('bash', ['-c', node.startCmd]); }
    _saveState();
  }
}

class BridgeNode extends ChangeNotifier {
  final String id, name, machine, role, startCmd, stopCmd; final int port; final IconData icon;
  bool _isUp = false, _isSleeping = false;
  BridgeNode({required this.id, required this.name, required this.machine, required this.role, required this.port, required this.icon, required this.startCmd, required this.stopCmd});
  bool get isUp => _isUp; set isUp(bool v) { _isUp = v; notifyListeners(); }
  bool get isSleeping => _isSleeping; set isSleeping(bool v) { _isSleeping = v; notifyListeners(); }
}

class _StatusIndicator extends StatefulWidget {
  final bool isUp, isSleeping;
  const _StatusIndicator({required this.isUp, required this.isSleeping});

  @override
  State<_StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<_StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSleeping ? Colors.orange : (widget.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F));
    return FadeTransition(
      opacity: (widget.isUp && !widget.isSleeping) ? _controller : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 10, height: 10, 
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          color: color, 
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
        ),
      ),
    );
  }
}
