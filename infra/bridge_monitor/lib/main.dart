import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/rendering.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'dart:ui' as ui; // 🧠 Mechanical: FragmentShader loading
import 'dart:math' as math;
import 'utils/telemetry_util.dart';
import 'widgets/exo_zoom.dart';

void main() {
  runApp(const ExoTechBridgeApp());
}

final pulseNotifier = ValueNotifier<double>(0.0);
final buildCountNotifier = ValueNotifier<int>(0);
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final agentModeNotifier = ValueNotifier<bool>(true);
final topCpuNotifier = ValueNotifier<List<String>>([]);
final memRssNotifier = ValueNotifier<String>("0/0 MB");
final currentIntervalNotifier = ValueNotifier<int>(1000);
final debugPaintNotifier = ValueNotifier<bool>(false);
final resetFlashNotifier = ValueNotifier<String?>(null);

ui.FragmentProgram? heartbeatProgram;

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🧠 Educational Context: Modular Zoom
    // We wrap the entire app in SovereignZoom to ensure all elements,
    // including the header, scale uniformly as per ExoTalk's design.
    return ExoZoom(
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
            ),
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFAEB2B8), // 🧠 Dashboard Gray
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00C9A7), brightness: Brightness.light),
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

class _BridgeMonitorScreenState extends State<BridgeMonitorScreen> with SingleTickerProviderStateMixin {
  late AnimationController _heartbeatController;
  bool _isGridView = true;
  String _localHost = "DISCOVERING...";
  late List<BridgeNode> _nodes;
  Timer? _refreshTimer;
  bool _isScanning = false;
  int _consecutiveSteadyStates = 0;
  File? _sessionLogFile;
  Timer? _heartbeatTimer; // 🧠 Mechanical: 30Hz Process Clock
  int _lastPulseUpdate = 0;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  _BridgeMonitorScreenState() {
    _nodes = [
      BridgeNode(id: "signaling-1", name: "Signaling Relay", machine: "EXONOMY", role: "WebRTC Handshake Bridge", port: 8080, icon: Icons.hub_outlined, serviceName: "exotalk-signaling"),
      BridgeNode(id: "conscia-1", name: "Conscia Beacon", machine: "EXONOMY", role: "P2P Mesh Node (Sovereign)", port: 3000, icon: Icons.radar_outlined, serviceName: "exotalk-conscia"),
      BridgeNode(id: "proxy-1", name: "Public Proxy", machine: "ZROK INFRA", role: "External Gateway (exotalk.tech)", port: 0, icon: Icons.public_outlined, serviceName: "exotalk-zrok"),
    ];
  }

  @override
  void initState() {
    super.initState();
    _heartbeatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    
    ui.FragmentProgram.fromAsset('assets/shaders/heartbeat.frag').then((program) {
      heartbeatProgram = program;
      if (mounted) setState(() {});
    });
    
    _scheduleNextTick();
    
    _initStorage();
    _loadState().then((_) {
      setState(() { _localHost = Platform.localHostname.toUpperCase(); });
      _syncSystemStates(); // 🧠 New: Sync enable/disable states at boot
      _performScan();
    });
    _startPolling(const Duration(seconds: 5));
  }

  void _scheduleNextTick() {
    bool hasActiveNodes = _nodes.any((n) => n.isUp && !n.isSleeping);
    int targetInterval = hasActiveNodes ? 33 : 200; // 30Hz Active / 5Hz Idle
    
    _heartbeatTimer = Timer(Duration(milliseconds: targetInterval), () {
      if (!mounted) return;
      pulseNotifier.value = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _scheduleNextTick();
    });
  }

  Future<void> _syncSystemStates() async {
    for (var node in _nodes) {
      final res = await Process.run('systemctl', ['--user', 'is-enabled', node.serviceName]);
      setState(() { node.isAutostart = res.stdout.toString().trim() == 'enabled'; });
    }
  }

  void _startPolling(Duration interval) {
    _refreshTimer?.cancel();
    currentIntervalNotifier.value = interval.inMilliseconds;
    _refreshTimer = Timer.periodic(interval, (_) => _performScan());
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _heartbeatTimer?.cancel(); // 🧠 Mechanical Cleanup
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

    try {
      // 🧠 Audit: Moving telemetry to main thread to diagnose isolate stalling.
      // We still use a Future to keep it asynchronous.
      final results = await () async {
        try {
          final activeProcesses = TelemetryUtil.getActiveProcesses();
          final nodeStatuses = <String, bool>{};
          for (var node in _nodes) {
            if (node.id.startsWith("signaling")) {
              nodeStatuses[node.id] = TelemetryUtil.isProcessRunning(activeProcesses, "signaling_server");
            } else if (node.id.startsWith("conscia")) {
              nodeStatuses[node.id] = node.isSleeping ? false : TelemetryUtil.isProcessRunning(activeProcesses, "conscia");
            } else if (node.id.startsWith("proxy")) {
              nodeStatuses[node.id] = TelemetryUtil.isProcessRunning(activeProcesses, "zrok");
            } else if (node.id.startsWith("qdrant") || node.id.startsWith("arize")) {
              nodeStatuses[node.id] = TelemetryUtil.isProcessRunning(activeProcesses, node.id.split("-")[0]);
            } else if (node.id == "nginx") {
              nodeStatuses[node.id] = TelemetryUtil.isProcessRunning(activeProcesses, "nginx");
            }
          }
          final mem = agentModeNotifier.value ? TelemetryUtil.getSystemMemory() : null;
          print("TELEMETRY_LOG: Nodes: ${nodeStatuses.values.where((v) => v).length} UP, Mem: $mem");
          return {
            'nodes': nodeStatuses,
            'mem': mem,
          };
        } catch (e) {
          print("TELEMETRY_ERROR: $e");
          return {'nodes': <String, bool>{}, 'mem': null};
        }
      }();

      final nodeStatuses = results['nodes'] as Map<String, bool>;
      for (var node in _nodes) {
        if (nodeStatuses.containsKey(node.id)) node.isUp = nodeStatuses[node.id]!;
      }

      if (results['mem'] != null) {
        topCpuNotifier.value = ["TELEMETRY_ISOLATE_ACTIVE"];
        memRssNotifier.value = results['mem'] as String;
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
    } else if (key == '1') {
      final node = _nodes.firstWhere((n) => n.id == 'signaling-1');
      _toggleService(node);
    } else if (key == '2') {
      final node = _nodes.firstWhere((n) => n.id == 'conscia-1');
      int nextState = node.isSleeping ? 2 : (node.isUp ? 0 : 1);
      _cycleConscia(node, nextState);
    } else if (key == '3') {
      final node = _nodes.firstWhere((n) => n.id == 'proxy-1');
      _toggleService(node);
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
          debugRepaintRainbowEnabled = debugPaint;
          buildCountNotifier.value++; // 🧠 Audit: Tracking global rebuilds
          return child!;
        },
        child: Scaffold(
          body: Column(
            children: [
              RepaintBoundary(child: _buildPremiumHeader(isDark)),
              Expanded(child: RepaintBoundary(child: _isGridView ? _buildGrid(isDark) : _buildList(isDark))),
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
        color: isDark ? const Color(0xFF141414) : const Color(0xFFE1E4E8),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFC0C4C8), width: 1)),
      ),
      child: Row(
        children: [
          Image.asset('assets/exotalk_pappus_desktop.png', width: 96, height: 96),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("EXOTECH BRIDGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
              Text("ACTIVE TELEMETRY | NODE: $_localHost | v1.3.0-LEGISLATOR", style: const TextStyle(fontSize: 14, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
              ValueListenableBuilder<int>(
                valueListenable: buildCountNotifier,
                builder: (context, count, _) => Text("BUILD COUNT: $count", style: const TextStyle(fontSize: 9, color: Color(0xFF664400))),
              ),
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: currentIntervalNotifier,
                    builder: (context, interval, _) => Text(
                      "AGENT MODE | INTERVAL: ${interval}ms | STEADY: $_consecutiveSteadyStates",
                      style: const TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<List<String>>(
                    valueListenable: topCpuNotifier,
                    builder: (context, top, _) => Text(
                      top.take(1).join(", "),
                      style: const TextStyle(fontSize: 9, color: Color(0xFFCC7A00)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 24, color: isDark ? Colors.white24 : Colors.black26),
              const SizedBox(width: 16),
              ValueListenableBuilder<String>(
                valueListenable: memRssNotifier,
                builder: (context, rss, _) => Text(
                  "MEM: $rss",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
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
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minWidth: 280), height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: node.isUp ? const Color(0xFF003D33) : const Color(0xFF4D1D1D)),
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
              Icon(node.icon, color: node.isUp ? const Color(0xFF006654) : const Color(0xFF803030), size: 16),
            ]),
            const SizedBox(height: 8),
            Text(node.role, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
               CupertinoSlidingSegmentedControl<int>(
                 groupValue: node.isSleeping ? 1 : (node.isUp ? 2 : 0),
                 children: {0: const Icon(Icons.power_off, size: 14), 1: const Icon(Icons.bedtime, size: 14), 2: const Icon(Icons.power, size: 14)},
                 onValueChanged: (v) { if (v != null) _setNodeState(node, v); },
               )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeRow(BridgeNode node, bool isDark) {
    return ListenableBuilder(
      listenable: node,
      builder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(minWidth: 700),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: node.isUp ? const Color(0xFF003D33).withOpacity(0.3) : const Color(0xFF4D1D1D).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            RepaintBoundary(child: _StatusIndicator(isUp: node.isUp, isSleeping: node.isSleeping)),
            const SizedBox(width: 24),
            Icon(node.icon, color: node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F), size: 20),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                  Text("${node.role} • ${node.machine} • PORT: ${node.port}", style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black87)),
                ]
              )
            ),
            const SizedBox(width: 24),
            CupertinoSlidingSegmentedControl<int>(
              groupValue: node.isSleeping ? 1 : (node.isUp ? 2 : 0),
              children: {
                0: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.power_off, size: 14)), 
                1: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.bedtime, size: 14)), 
                2: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.power, size: 14))
              },
              onValueChanged: (v) { if (v != null) _setNodeState(node, v); },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleService(BridgeNode node) async {
    final newState = node.isUp ? 0 : 2;
    _setNodeState(node, newState);
  }

  void _setNodeState(BridgeNode node, int state) async {
    // 🧠 Educational Context: The "Legislator" Role
    // As of v1.1.7, the Bridge Monitor acts as the native "Legislator" of the
    // Exonomy node. We have purged all legacy 'sshpass' wrappers that were used 
    // when the monitor was remote. It now issues direct, native 'systemctl' 
    // commands to the local host, ensuring deterministic service state control.
    if (state == 0) {
      setState(() { node.isSleeping = false; node.isUp = false; });
      await Process.run('systemctl', ['--user', 'stop', node.serviceName]);
    } else if (state == 1) {
      // 🧠 Educational Context: The Observer Model
      // The "Sleep" state (1) implements the Observer Model. We update the UI 
      // to reflect a sleeping state, but we DO NOT stop the background daemon. 
      // This allows the service to remain active for background tasks (like 
      // telemetry or P2P handshakes) while informing the user that active 
      // UI-driven orchestration is paused.
      setState(() { node.isSleeping = true; node.isUp = false; });
    } else if (state == 2) {
      setState(() { node.isSleeping = false; node.isUp = true; });
      await Process.run('systemctl', ['--user', 'start', node.serviceName]);
    }
    _saveState();
  }

  void _cycleConscia(BridgeNode node, int state) async {
    _setNodeState(node, state);
  }
}

class BridgeNode extends ChangeNotifier {
  final String id, name, machine, role, serviceName; final int port; final IconData icon;
  bool _isUp = false, _isSleeping = false, _isAutostart = false;
  BridgeNode({required this.id, required this.name, required this.machine, required this.role, required this.port, required this.icon, required this.serviceName});
  bool get isUp => _isUp; set isUp(bool v) { if (_isUp == v) return; _isUp = v; notifyListeners(); }
  bool get isSleeping => _isSleeping; set isSleeping(bool v) { if (_isSleeping == v) return; _isSleeping = v; notifyListeners(); }
  bool get isAutostart => _isAutostart; set isAutostart(bool v) { if (_isAutostart == v) return; _isAutostart = v; notifyListeners(); }
}

class _StatusIndicator extends StatelessWidget {
  final bool isUp, isSleeping;
  const _StatusIndicator({required this.isUp, required this.isSleeping});

  @override
  Widget build(BuildContext context) {
    if (heartbeatProgram == null) return const SizedBox(width: 14, height: 14);
    
    final color = isSleeping ? Colors.orange : (isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F));
    
    return ValueListenableBuilder<double>(
      valueListenable: pulseNotifier,
      builder: (context, timeValue, _) => CustomPaint(
        size: const Size(14, 14),
        painter: _HeartbeatPainter(
          shader: heartbeatProgram!.fragmentShader(),
          time: timeValue,
          color: color,
          isActive: isUp && !isSleeping,
        ),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Color color;
  final bool isActive;

  _HeartbeatPainter({
    required this.shader, 
    required this.time, 
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, isActive ? time : 0.0); // Stop pulse if not active
    shader.setFloat(3, color.red / 255.0);
    shader.setFloat(4, color.green / 255.0);
    shader.setFloat(5, color.blue / 255.0);
    shader.setFloat(6, color.alpha / 255.0);
    
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) {
    return old.time != time || old.color != color || old.isActive != isActive;
  }
}
