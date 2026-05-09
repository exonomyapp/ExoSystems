import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'utils/telemetry_util.dart';
import 'widgets/exo_zoom.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    File('/home/exocrat/bridge_monitor_clicks.log').writeAsStringSync('${DateTime.now().toIso8601String()} | STARTUP | v1.5.0-BRIDGE\n', mode: FileMode.append);
  } catch (_) {}
  
  runApp(const ExoTechBridgeApp());
}

final buildCountNotifier = ValueNotifier<int>(0);
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
final agentModeNotifier = ValueNotifier<bool>(true);
final topCpuNotifier = ValueNotifier<List<String>>([]);
final memRssNotifier = ValueNotifier<String>("0/0 MB");
final currentIntervalNotifier = ValueNotifier<int>(1000);
final debugPaintNotifier = ValueNotifier<bool>(false);

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              scaffoldBackgroundColor: const Color(0xFFAEB2B8),
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
  bool _isGridView = true;
  String _localHost = "DISCOVERING...";
  late List<BridgeNode> _nodes;
  Timer? _refreshTimer;
  bool _isScanning = false;
  int _consecutiveSteadyStates = 0;
  bool _consciaSleeping = false;
  bool _signalingSleeping = false;
  bool _zrokSleeping = false;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  _BridgeMonitorScreenState() {
    _nodes = [
      BridgeNode(id: "signaling", name: "Signaling Relay", machine: "EXONOMY", role: "WebRTC Handshake Bridge", port: 8080, icon: Icons.hub_outlined, startCmd: "start", stopCmd: "stop", serviceName: "exotalk-signaling"),
      BridgeNode(id: "conscia", name: "Conscia Beacon", machine: "EXONOMY", role: "P2P Mesh Node (Sovereign)", port: 3000, icon: Icons.radar_outlined, startCmd: "start", stopCmd: "stop", serviceName: "exotalk-conscia"),
      BridgeNode(id: "zrok", name: "Public Proxy", machine: "ZROK INFRA", role: "External Gateway (exotalk.tech)", port: 0, icon: Icons.public_outlined, startCmd: "start", stopCmd: "stop", serviceName: "exotalk-zrok"),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadState().then((_) {
      setState(() { _localHost = Platform.localHostname.toUpperCase(); });
      _performScan();
    });
    _startPolling(const Duration(seconds: 5));
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

  Future<void> _saveState() async {
    try {
      final config = {
        'nodes': _nodes.map((n) => {'id': n.id, 'intendedUp': n.isUp, 'isSleeping': n.isSleeping}).toList(),
        'theme': themeModeNotifier.value.index,
        'isGridView': _isGridView,
        'consciaSleeping': _consciaSleeping,
        'signalingSleeping': _signalingSleeping,
        'zrokSleeping': _zrokSleeping,
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
        setState(() { 
          _isGridView = config['isGridView'] ?? true; 
          _consciaSleeping = config['consciaSleeping'] ?? false;
          _signalingSleeping = config['signalingSleeping'] ?? false;
          _zrokSleeping = config['zrokSleeping'] ?? false;
        });
        final pNodes = config['nodes'] as List?;
        if (pNodes != null) {
          for (var pNode in pNodes) {
            final nodeIndex = _nodes.indexWhere((n) => n.id == pNode['id']);
            if (nodeIndex != -1) {
              _nodes[nodeIndex] = _nodes[nodeIndex].copyWith(
                isSleeping: pNode['isSleeping'] ?? false,
                isUp: pNode['intendedUp'] ?? false,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _performScan() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final activeProcesses = TelemetryUtil.getActiveProcesses();
      List<BridgeNode> updatedNodes = [];
      
      for (var node in _nodes) {
        final isUp = TelemetryUtil.isProcessRunning(activeProcesses, node.id);
        bool isSleeping = false;
        if (node.id == 'conscia') isSleeping = _consciaSleeping;
        if (node.id == 'signaling') isSleeping = _signalingSleeping;
        if (node.id == 'zrok') isSleeping = _zrokSleeping;
        
        final hasTraffic = isUp && !isSleeping && TelemetryUtil.hasActiveTraffic(node.port, pattern: node.id);

        updatedNodes.add(node.copyWith(
          isUp: isUp, 
          isSleeping: isSleeping,
          hasTraffic: hasTraffic,
        ));
      }
      
      setState(() { _nodes = updatedNodes; });
      
      final mem = agentModeNotifier.value ? TelemetryUtil.getSystemMemory() : null;
      if (mem != null) {
        memRssNotifier.value = mem;
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
    } else {
      final val = int.tryParse(key);
      if (val != null && val >= 1 && val <= 9) {
        _setNodeState(_nodes[(val - 1) ~/ 3], (val - 1) % 3);
      }
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
          buildCountNotifier.value++;
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFE1E4E8),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFC0C4C8), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo & Title Group
          Row(
            children: [
              Image.asset('assets/exotalk_pappus_desktop.png', width: 96, height: 96),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("EXOTECH BRIDGE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text("ACTIVE TELEMETRY | NODE: $_localHost", style: const TextStyle(fontSize: 14, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  const Text("v1.5.0-BRIDGE", style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                  ValueListenableBuilder<int>(
                    valueListenable: buildCountNotifier,
                    builder: (context, count, _) => Text("BUILD COUNT: $count", style: const TextStyle(fontSize: 9, color: Color(0xFF664400))),
                  ),
                ],
              ),
            ],
          ),
          // HUD Center
          RepaintBoundary(child: _buildCenteredHUD(isDark)),
          // Controls Right
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.scale(scale: 0.7, alignment: Alignment.centerRight, child: _buildViewToggle(isDark)),
              const SizedBox(height: 8),
              Transform.scale(scale: 0.7, alignment: Alignment.centerRight, child: _buildThemeToggle(isDark)),
              const SizedBox(height: 8),
              Transform.scale(scale: 0.7, alignment: Alignment.centerRight, child: _buildAgentToggle(isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentToggle(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: agentModeNotifier,
      builder: (context, isVisible, _) {
        return CupertinoSlidingSegmentedControl<bool>(
          groupValue: isVisible,
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDEE0E4),
          thumbColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
          padding: const EdgeInsets.all(2),
          children: {
            true: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text("HUD ON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isVisible ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38)))),
            false: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text("HUD OFF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: !isVisible ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38)))),
          },
          onValueChanged: (v) { if (v != null) agentModeNotifier.value = v; },
        );
      },
    );
  }

  void _cycleNodeState(BridgeNode node) {
    int currentState = node.isSleeping ? 1 : (node.isUp ? 2 : 0);
    int nextState = (currentState + 1) % 3;
    _setNodeState(node, nextState);
  }

  Widget _buildViewToggle(bool isDark) {
    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: _isGridView,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDEE0E4),
      thumbColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
      padding: const EdgeInsets.all(2),
      children: {
        true: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.grid_view, size: 16, color: _isGridView ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38))),
        false: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.view_list, size: 16, color: !_isGridView ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38))),
      },
      onValueChanged: (v) { if (v != null) { setState(() { _isGridView = v; }); _saveState(); } },
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    final currentMode = themeModeNotifier.value;
    final selectedIndex = currentMode == ThemeMode.light ? 0 : currentMode == ThemeMode.system ? 1 : 2;

    return CupertinoSlidingSegmentedControl<int>(
      groupValue: selectedIndex,
      backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDEE0E4),
      thumbColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
      padding: const EdgeInsets.all(2),
      children: {
        0: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(CupertinoIcons.sun_max_fill, size: 14,
            color: selectedIndex == 0 ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38)),
        ),
        1: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(CupertinoIcons.circle_lefthalf_fill, size: 14,
            color: selectedIndex == 1 ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38)),
        ),
        2: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(CupertinoIcons.moon_fill, size: 14,
            color: selectedIndex == 2 ? const Color(0xFF00C9A7) : (isDark ? Colors.white38 : Colors.black38)),
        ),
      },
      onValueChanged: (v) { 
        if (v != null) {
          themeModeNotifier.value = v == 0 ? ThemeMode.light : (v == 1 ? ThemeMode.system : ThemeMode.dark); 
          _saveState(); 
        } 
      },
    );
  }

  Widget _buildCenteredHUD(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: agentModeNotifier,
      builder: (context, isVisible, _) {
        if (!isVisible) return const SizedBox.shrink();
        return Container(
          width: 250,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFC0C4C8), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: currentIntervalNotifier,
                builder: (context, interval, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("POLL INTERVAL", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                    Text("${interval}ms", style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("STEADY STATES", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                  Text("$_consecutiveSteadyStates", style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                ],
              ),
              ValueListenableBuilder<String>(
                valueListenable: memRssNotifier,
                builder: (context, rss, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("MEMORY RSS", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.bold)),
                    Text(rss, style: const TextStyle(fontSize: 12, color: Color(0xFF00C9A7), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(bool isDark) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(48),
        child: LayoutGrid(
          columnSizes: repeat(3, [1.fr]),
          rowSizes: repeat(_nodes.length ~/ 3 + 1, [auto]),
          rowGap: 32, columnGap: 32,
          children: _nodes.map((node) => _buildNodeCard(node, isDark)).toList(),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _nodes.map((node) => _buildNodeRow(node, isDark)).toList(),
        ),
      ),
    );
  }

  Widget _buildNodeCard(BridgeNode node, bool isDark) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280), height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: node.isUp ? const Color(0xFF003D33) : const Color(0xFF4D1D1D)),
      ),
      child: InkWell(
        onTap: () => _cycleNodeState(node),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                RepaintBoundary(
                  child: _StatusIndicator(
                    isUp: node.isUp, 
                    isSleeping: node.isSleeping,
                    hasTraffic: node.hasTraffic,
                  ),
                ), 
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
      ),
    );
  }

  Widget _buildNodeRow(BridgeNode node, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: node.isUp ? const Color(0xFF003D33).withOpacity(0.3) : const Color(0xFF4D1D1D).withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _cycleNodeState(node),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              RepaintBoundary(
                child: _StatusIndicator(
                  isUp: node.isUp, 
                  isSleeping: node.isSleeping,
                  hasTraffic: node.hasTraffic,
                ),
              ),
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
      ),
    );
  }

  void _setNodeState(BridgeNode node, int state) async {
    try {
      final logFile = File('/home/exocrat/bridge_monitor_clicks.log');
      final timestamp = DateTime.now().toIso8601String();
      final stateStr = state == 0 ? "OFF" : (state == 1 ? "SLEEP" : "ON");
      await logFile.writeAsString('$timestamp | NODE: ${node.id} | ACTION: $stateStr\n', mode: FileMode.append);
    } catch (_) {}

    if (state == 0) {
      if (node.id == 'conscia') _consciaSleeping = false;
      if (node.id == 'signaling') _signalingSleeping = false;
      if (node.id == 'zrok') _zrokSleeping = false;
      await Process.run('systemctl', ['--user', 'stop', '${node.serviceName}.service']);
    } else if (state == 1) {
      if (node.id == 'conscia') _consciaSleeping = true;
      if (node.id == 'signaling') _signalingSleeping = true;
      if (node.id == 'zrok') _zrokSleeping = true;
    } else if (state == 2) {
      if (node.id == 'conscia') _consciaSleeping = false;
      if (node.id == 'signaling') _signalingSleeping = false;
      if (node.id == 'zrok') _zrokSleeping = false;
      await Process.run('systemctl', ['--user', 'start', '${node.serviceName}.service']);
    }
    _performScan();
    _saveState();
  }
}

class BridgeNode {
  final String id, name, machine, role, startCmd, stopCmd, serviceName;
  final int port;
  final IconData icon;
  final bool isUp;
  final bool isSleeping;
  final bool hasTraffic;

  BridgeNode({
    required this.id,
    required this.name,
    required this.machine,
    required this.role,
    required this.port,
    required this.icon,
    required this.startCmd,
    required this.stopCmd,
    required this.serviceName,
    this.isUp = false,
    this.isSleeping = false,
    this.hasTraffic = false,
  });

  BridgeNode copyWith({bool? isUp, bool? isSleeping, bool? hasTraffic}) {
    return BridgeNode(
      id: id,
      name: name,
      machine: machine,
      role: role,
      port: port,
      icon: icon,
      startCmd: startCmd,
      stopCmd: stopCmd,
      serviceName: serviceName,
      isUp: isUp ?? this.isUp,
      isSleeping: isSleeping ?? this.isSleeping,
      hasTraffic: hasTraffic ?? this.hasTraffic,
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isUp;
  final bool isSleeping;
  final bool hasTraffic;

  const _StatusIndicator({
    required this.isUp, 
    required this.isSleeping,
    this.hasTraffic = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkUnlitGreen = const Color(0xFF003D33);
    final intenseNeonGreen = const Color(0xFF00FFC9);
    final staticRed = const Color(0xFFFF5F5F);
    final staticYellow = Colors.orange;

    if (!isUp) {
      return _buildDot(staticRed);
    }

    if (isSleeping) {
      return _buildDot(staticYellow);
    }

    if (hasTraffic) {
      return _buildDot(intenseNeonGreen);
    }

    return _buildDot(darkUnlitGreen);
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
