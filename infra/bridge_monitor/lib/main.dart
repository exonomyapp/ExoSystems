import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';

// ============================================================================
// ExoTech Bridge Monitor
//
// Advanced diagnostic dashboard featuring dynamic discovery, persistent
// log capture (via journalctl/tail), and interactive UI states for federated
// node analysis.
// ============================================================================

void main() {
  runApp(const ExoTechBridgeApp());
}

// ----------------------------------------------------------------------------
// THEME STATE MANAGEMENT
// We use a global ValueNotifier to track ThemeMode (Light/System/Dark).
// This allows the entire application to react to theme changes without
// requiring a complex state management library like Riverpod or Bloc
// for this specific standalone diagnostic tool.
// ----------------------------------------------------------------------------
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'ExoTech Bridge',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          // Premium Dark Theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00C9A7),
              brightness: Brightness.dark,
              surface: const Color(0xFF141414),
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
              displayLarge: GoogleFonts.outfit(color: const Color(0xFFB0B4BE), fontWeight: FontWeight.w900),
              bodyLarge: GoogleFonts.outfit(color: const Color(0xFF8E929B)),
              bodyMedium: GoogleFonts.outfit(color: const Color(0xFF787C87)),
            ),
          ),
          // Premium Light Theme — No pure white
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFD1D3D8), // Premium dashboard gray
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00C9A7),
              brightness: Brightness.light,
              surface: const Color(0xFFE8E9EB), // Soft light gray surfaces
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
              displayLarge: GoogleFonts.outfit(color: const Color(0xFF3D4446), fontWeight: FontWeight.w900),
              bodyLarge: GoogleFonts.outfit(color: const Color(0xFF5F6368)),
              bodyMedium: GoogleFonts.outfit(color: const Color(0xFF70757A)),
            ),
          ),
          home: const BridgeMonitorScreen(),
        );
      },
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
  List<BridgeNode> _nodes = [];
  String? _isolatedNodeId; // Tracks which node is currently expanded/isolated
  String? _lastKey;
  
  Timer? _refreshTimer;
  bool _isScanning = false;
  File? _sessionLogFile;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initStorage();
    _initDiscovery();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _performScan());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // ==========================================
  // LOCAL STORAGE & PERSISTENCE
  // ==========================================
  
  /// Initializes the local logging directory.
  /// Essential for "Testing Season" analysis where node failure states
  /// must be preserved across app restarts.
  Future<void> _initStorage() async {
    final dir = Directory('logs');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _sessionLogFile = File('logs/session.log');
    if (!await _sessionLogFile!.exists()) {
      await _sessionLogFile!.create();
    }
  }

  /// Synchronously appends newly fetched log lines to the persistent file.
  void _appendLogToFile(String nodeId, List<String> newLogs) {
    if (_sessionLogFile == null || newLogs.isEmpty) return;
    final timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer();
    for (var log in newLogs) {
      buffer.writeln('[$timestamp] [$nodeId] $log');
    }
    _sessionLogFile!.writeAsStringSync(buffer.toString(), mode: FileMode.append);
  }

  Future<void> _initDiscovery() async {
    setState(() {
      _localHost = Platform.localHostname.toUpperCase();
    });
    // Create initial node shells
    _nodes = [
      BridgeNode(
        id: "signaling-1", name: "Signaling Relay", machine: _localHost, role: "WebRTC Handshake Bridge", port: 8080, icon: Icons.hub_outlined,
        startCmd: "systemctl --user start exotalk-signaling",
        stopCmd: "systemctl --user stop exotalk-signaling",
      ),
      BridgeNode(
        id: "beacon-1", name: "Conscia Beacon", machine: _localHost, role: "P2P Mesh Node (Sovereign)", port: 3000, icon: Icons.radar_outlined,
        startCmd: "nohup bash -c 'cd /home/exocrat/code/exotalk/exotalk_engine/conscia && cargo run --release > /home/exocrat/conscia.log 2>&1' &",
        stopCmd: "pkill -f 'conscia'",
      ),
      BridgeNode(
        id: "proxy-1", name: "Public Proxy", machine: "ZROK INFRA", role: "External Gateway (exotalk.tech)", port: 0, icon: Icons.public_outlined,
        startCmd: "systemctl --user start exotalk-zrok",
        stopCmd: "systemctl --user stop exotalk-zrok",
      ),
    ];
    await _performScan();
  }

  Future<void> _performScan() async {
    if (_isScanning) return;
    _isScanning = true;

    for (var node in _nodes) {
      if (node.id.startsWith("signaling")) {
        final res = await Process.run('systemctl', ['--user', 'is-active', 'exotalk-signaling']);
        node.isUp = res.exitCode == 0;
        final logs = await _fetchJournalctlLogs("exotalk-signaling");
        _updateLogs(node, logs);
      } else if (node.id.startsWith("beacon")) {
        if (node.isSleeping) {
          node.isUp = false;
          continue;
        }
        final res = await Process.run('pgrep', ['-f', 'conscia']);
        node.isUp = res.exitCode == 0;
        final logs = await _fetchTailLogs("/home/exocrat/conscia.log");
        _updateLogs(node, logs);
      } else if (node.id.startsWith("proxy")) {
        final res = await Process.run('systemctl', ['--user', 'is-active', 'exotalk-zrok']);
        node.isUp = res.exitCode == 0;
        final logs = await _fetchJournalctlLogs("exotalk-zrok");
        _updateLogs(node, logs);
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _updateLogs(BridgeNode node, List<String> fetchedLogs) {
    if (fetchedLogs.isEmpty) return;
    
    // Efficiently find new logs using a temporary Set for lookup
    // We only care about matching against the existing logs
    final existingLogsSet = node.logs.toSet();
    final newLogs = fetchedLogs.where((l) => !existingLogsSet.contains(l)).toList();
    
    if (newLogs.isNotEmpty) {
      node.logs.addAll(newLogs);
      
      // Keep only the last 1000 logs in memory to prevent bloat
      if (node.logs.length > 1000) {
        node.logs.removeRange(0, node.logs.length - 1000);
      }
      
      _appendLogToFile(node.id, newLogs);
    }
  }

  Future<List<String>> _fetchJournalctlLogs(String service) async {
    try {
      final res = await Process.run('journalctl', ['--user', '-u', service, '-n', '50', '--no-pager']);
      if (res.exitCode == 0) {
        return res.stdout.toString().split('\n').where((s) => s.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<String>> _fetchTailLogs(String path) async {
    try {
      final res = await Process.run('tail', ['-n', '50', path]);
      if (res.exitCode == 0) {
        return res.stdout.toString().split('\n').where((s) => s.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> _checkPort(int port) async {
    try {
      final s = await Socket.connect('localhost', port, timeout: const Duration(milliseconds: 500));
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkProcess(String pattern) async {
    try {
      final res = await Process.run('pgrep', ['-f', pattern]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }



  void _toggleIsolation(String nodeId) {
    setState(() {
      if (_isolatedNodeId == nodeId) {
        _isolatedNodeId = null; // Un-isolate
      } else {
        _isolatedNodeId = nodeId; // Isolate new (cross-card transition)
      }
    });
  }

  // ----------------------------------------------------------------------------
  // REMOTE KEYBOARD CONTROL
  // Shortcuts mapped to xdotool keys for deterministic UI testing.
  // ----------------------------------------------------------------------------
  void _handleShortcut(String key) {
    print("DEBUG: Received shortcut key: $key");
    if (key == 't') {
      final current = themeModeNotifier.value;
      if (current == ThemeMode.dark) themeModeNotifier.value = ThemeMode.light;
      else if (current == ThemeMode.light) themeModeNotifier.value = ThemeMode.system;
      else themeModeNotifier.value = ThemeMode.dark;
      setState(() {});
    } else if (key == 'v') {
      setState(() => _isGridView = !_isGridView);
    } else if (key == 'r') {
      _performScan();
    } else if (key == '1') {
      // Toggle Signaling
      final node = _nodes.firstWhere((n) => n.id == 'signaling-1');
      _triggerToggle(node);
    } else if (key == '2') {
      // Cycle Conscia
      final node = _nodes.firstWhere((n) => n.id == 'beacon-1');
      int current = 0;
      if (node.isSleeping) current = 1;
      else if (node.isUp) current = 2;
      final next = (current + 1) % 3;
      _triggerConscia(node, next);
    } else if (key == '3') {
      // Toggle Proxy
      final node = _nodes.firstWhere((n) => n.id == 'proxy-1');
      _triggerToggle(node);
    }
  }

  void _triggerToggle(BridgeNode node) {
    // Optimistic UI update
    setState(() {
      node.isUp = !node.isUp;
    });
    if (node.isUp) {
      if (node.startCmd != null) Process.run('bash', ['-c', node.startCmd!]);
    } else {
      if (node.stopCmd != null) Process.run('bash', ['-c', node.stopCmd!]);
    }
    Future.delayed(const Duration(seconds: 2), _performScan);
  }

  void _triggerConscia(BridgeNode node, int state) async {
    // This replicates the logic in ConsciaTristateToggle for remote testing
    await Process.run('bash', ['-c', "pkill -f 'cargo run' ; pkill -f 'conscia'"]);
    if (state == 0) {
      setState(() {
        node.isSleeping = false;
        node.isUp = false;
      });
    } else if (state == 1) {
      setState(() {
        node.isSleeping = true;
        node.isUp = false;
      });
    } else if (state == 2) {
      setState(() {
        node.isSleeping = false;
        node.isUp = true;
      });
      await Process.start('cargo', ['run', '--release'],
        workingDirectory: '/home/exocrat/code/exotalk/exotalk_engine/conscia',
        mode: ProcessStartMode.detached,
        environment: {'HOME': '/home/exocrat', 'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/exocrat/.cargo/bin'},
      );
    }
    Future.delayed(const Duration(seconds: 1), _performScan);
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor = isDark ? Colors.white : const Color(0xFF2D3436);

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel.toLowerCase();
          setState(() => _lastKey = key);
          _handleShortcut(key);
        }
      },
      child: GestureDetector(
        // Clicking the background removes isolation
          onTap: () {
            if (_isolatedNodeId != null) {
              setState(() => _isolatedNodeId = null);
            }
          },
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumHeader(isDark, logoColor),
                Expanded(
                  child: _nodes.isEmpty 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 800),
                        child: _isGridView ? _buildGrid() : _buildList(),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildPremiumHeader(bool isDark, Color logoColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : const Color(0xFFF8F9FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // ------------------------------------------------
          // ENLARGED IN-APP LOGO (128px)
          // ------------------------------------------------
          // ------------------------------------------------------------------
          // DYNAMIC BRANDING ASSET
          // The logo switches between 'realistic' and 'minimal' based on
          // the view mode, and 'logoColor' adapts to the theme brightness.
          // AnimatedSwitcher provides a smooth cross-fade transition.
          // ------------------------------------------------------------------
          // ------------------------------------------------------------------
          // DYNAMIC BRANDING ASSET
          // Light mode → full-color logo. Dark mode → monochromatic logo.
          // View mode does not affect the logo color selection.
          // ------------------------------------------------------------------
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Image.asset(
              isDark
                ? 'assets/exotalk_pappus_realistic.png'
                : 'assets/exotalk_pappus_color.png',
              key: ValueKey(isDark),
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EXOTECH BRIDGE",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 28,
                  color: isDark ? const Color(0xFFD0D0D0) : const Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "ACTIVE TELEMETRY | NODE: $_localHost",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: const Color(0xFF00C9A7).withOpacity(0.8),
                ),
              ),
              if (_lastKey != null)
                Text(
                  "LAST KEY: $_lastKey",
                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const Spacer(),
          // ------------------------------------------------
          // CONTROLS (Stacked at end)
          // ------------------------------------------------
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildViewToggle(isDark),
              const SizedBox(width: 8),
              _ThemeTristateToggle(
                currentMode: themeModeNotifier.value,
                onChanged: (mode) {
                  setState(() {
                    themeModeNotifier.value = mode;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleOption(
            icon: Icons.grid_view_rounded,
            isSelected: _isGridView,
            isDark: isDark,
            onTap: () => setState(() => _isGridView = true),
          ),
          _ViewToggleOption(
            icon: Icons.view_list_rounded,
            isSelected: !_isGridView,
            isDark: isDark,
            onTap: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }


  // ==========================================
  // DYNAMIC GRID & CARD LOGIC
  // ==========================================

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          // Grid measurements
          final gridCardWidth = (maxWidth - 64) / 3;
          final gridCardHeight = gridCardWidth / 1.4;

          // Isolation measurements
          const isoCardWidth = 350.0;
          const isoMainCardHeight = 250.0;
          const isoCompactCardHeight = 125.0;
          const spacing = 16.0;

          // ------------------------------------------------------------------
          // 2D STACK ANIMATION (GRID TO ISOLATED)
          // We use a Stack with AnimatedPositioned children to achieve
          // explicit 2D slide transitions. When a node is selected, it 
          // slides to the primary 'isolated' slot, while others compact 
          // and slide into a vertical list on the left.
          // ------------------------------------------------------------------
          return Stack(
            children: [
              // Slide-out Log Viewer
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                left: _isolatedNodeId != null ? isoCardWidth + 32 : maxWidth,
                top: 0,
                width: maxWidth - isoCardWidth - 32,
                height: maxHeight,
                child: LogViewer(
                  node: _nodes.firstWhere(
                    (n) => n.id == _isolatedNodeId, 
                    orElse: () => _nodes.first,
                  ),
                ),
              ),
              
              // Nodes
              ...List.generate(_nodes.length, (i) {
                final node = _nodes[i];
                final isIsolated = _isolatedNodeId == node.id;
                final isAnyIsolated = _isolatedNodeId != null;
                
                // Determine position
                double left;
                double top;
                double width;
                double height;

                if (!isAnyIsolated) {
                  // Grid layout
                  left = i * (gridCardWidth + 32);
                  top = 0;
                  width = gridCardWidth;
                  height = gridCardHeight;
                } else {
                  // Isolated layout
                  if (isIsolated) {
                    left = 0;
                    top = 0;
                    width = isoCardWidth;
                    height = isoMainCardHeight;
                  } else {
                    // Calculate rank among unselected nodes
                    int unselectedIdx = 0;
                    for (int j = 0; j < _nodes.length; j++) {
                      if (_nodes[j].id == _isolatedNodeId) continue;
                      if (_nodes[j].id == node.id) break;
                      unselectedIdx++;
                    }
                    
                    left = 0;
                    top = isoMainCardHeight + spacing + (unselectedIdx * (isoCompactCardHeight + spacing));
                    width = isoCardWidth;
                    height = isoCompactCardHeight;
                  }
                }

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: NodeCard(
                    node: node,
                    compact: isAnyIsolated && !isIsolated,
                    onTap: () => _toggleIsolation(node.id),
                    onToggled: () { setState(() {}); _performScan(); },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  // --- List View Logic ---

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      itemCount: _nodes.length,
      itemBuilder: (context, i) {
        final node = _nodes[i];
        final isExpanded = _isolatedNodeId == node.id;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NodeRow(
                node: node,
                onTap: () => _toggleIsolation(node.id),
                onToggled: () { setState(() {}); _performScan(); },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: isExpanded ? 300 : 0, // Accordion height
                margin: EdgeInsets.only(top: isExpanded ? 8 : 0),
                child: ClipRect(
                  child: isExpanded ? LogViewer(node: node) : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Data Models & Component Definitions
// ============================================================================

class BridgeNode {
  final String id;
  final String name;
  final String machine;
  final String role;
  final int port;
  final IconData icon;
  final String? startCmd;
  final String? stopCmd;
  bool isUp;
  bool isSleeping;
  List<String> logs;

  BridgeNode({
    required this.id,
    required this.name, 
    required this.machine, 
    required this.role, 
    required this.port, 
    required this.icon,
    this.startCmd,
    this.stopCmd,
    this.isUp = false,
    this.isSleeping = false,
    List<String>? logs,
  }) : logs = logs ?? [];
}

class LogViewer extends StatefulWidget {
  final BridgeNode node;
  const LogViewer({super.key, required this.node});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  String _filter = "";

  @override
  Widget build(BuildContext context) {
    final filteredLogs = widget.node.logs
        .where((l) => l.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        children: [
          // Sticky Header with Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))),
              color: isDark ? const Color(0xFF141414) : const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: const Color(0xFF00C9A7).withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text("SYSTEM LOGS: ${widget.node.id}",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: 12, 
                    color: isDark ? Colors.white70 : const Color(0xFF2D3436))),
                const SizedBox(width: 12),
                // ------------------------------------------
                // LIVE INDICATOR
                // Pulsing dot + log count so the user can
                // visually confirm data is actively updating
                // every 5-second polling cycle.
                // ------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulsingDot(),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.node.logs.length} entries",
                        style: GoogleFonts.outfit(fontSize: 10, color: const Color(0xFF00C9A7).withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  height: 30,
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Filter logs...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Log Output
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      filteredLogs[index],
                      style: GoogleFonts.firaCode(fontSize: 11, color: const Color(0xFFB0B0B0)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NodeCard extends StatelessWidget {
  final BridgeNode node;
  final VoidCallback onTap;
  final VoidCallback onToggled;
  final bool compact;
  
  const NodeCard({super.key, required this.node, required this.onTap, required this.onToggled, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = node.isSleeping 
        ? Colors.orange 
        : (node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F));
    final surfaceColor = isDark ? const Color(0xFF141414) : const Color(0xFFF1F3F4);
    final textMain = isDark ? const Color(0xFFA5AAB5) : const Color(0xFF2D3436);
    final textMuted = isDark ? const Color(0xFF787C87) : const Color(0xFF5F6368);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(node.icon, color: statusColor.withOpacity(0.8), size: compact ? 16 : 20),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  child: Text(
                    node.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 12 : 16,
                      color: textMain,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _StatusIndicator(isUp: node.isUp),
              ],
            ),
            SizedBox(height: compact ? 8 : 16),
            Text(
              node.isSleeping ? "SLEEPING" : (node.isUp ? "OPERATIONAL" : "INACTIVE"),
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: statusColor,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SOURCE: ${node.machine}",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textMain.withOpacity(0.85), // Intensified to match logo
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node.role,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: textMain.withOpacity(0.65), // Intensified
                      ),
                    ),
                  ],
                ),
                if (!compact)
                  GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: node.id.startsWith("beacon")
                        ? ConsciaTristateToggle(node: node, onToggled: onToggled)
                        : NodeKillSwitch(node: node, onToggled: onToggled),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NodeRow extends StatelessWidget {
  final BridgeNode node;
  final VoidCallback onTap;
  final VoidCallback onToggled;
  const NodeRow({super.key, required this.node, required this.onTap, required this.onToggled});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    final surfaceColor = isDark ? const Color(0xFF141414) : const Color(0xFFF1F3F4);
    final textMain = isDark ? const Color(0xFFA5AAB5) : const Color(0xFF2D3436);
    final textMuted = isDark ? const Color(0xFF787C87) : const Color(0xFF5F6368);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(isDark ? 0.1 : 0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(node.icon, color: statusColor.withOpacity(0.7), size: 20),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      fontSize: 14, 
                      color: textMain,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.role,
                    style: GoogleFonts.outfit(fontSize: 11, color: textMuted.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.isUp ? "ACTIVE" : "OFFLINE",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900, 
                      fontSize: 11, 
                      color: statusColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "PORT: ${node.port > 0 ? node.port : 'N/A'}",
                    style: GoogleFonts.outfit(fontSize: 10, color: textMuted.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                node.machine,
                style: GoogleFonts.outfit(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: textMuted,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(
              width: 170, // Fixed width prevents grid alignment breaking
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: node.id.startsWith("beacon")
                      ? ConsciaTristateToggle(node: node, onToggled: onToggled)
                      : NodeKillSwitch(node: node, onToggled: onToggled),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _StatusIndicator(isUp: node.isUp, isSleeping: node.isSleeping),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// PULSING STATUS INDICATOR
// A stateful widget that uses an AnimationController to continuously pulse 
// (fade opacity) when a node is 'Up'. This provides immediate visual 
// confirmation of a "living" system health state.
// ----------------------------------------------------------------------------
class _StatusIndicator extends StatefulWidget {
  final bool isUp;
  final bool isSleeping;
  const _StatusIndicator({required this.isUp, this.isSleeping = false});

  @override
  State<_StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<_StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isUp) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isUp != oldWidget.isUp || widget.isSleeping != oldWidget.isSleeping) {
      if (widget.isUp && !widget.isSleeping) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isSleeping 
        ? Colors.orange 
        : (widget.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F));
    
    return FadeTransition(
      opacity: (widget.isUp && !widget.isSleeping)
          ? Tween<double>(begin: 0.4, end: 1.0).animate(_controller)
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor,
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.4), 
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LIVE INDICATOR
// A continuously pulsing dot that provides visual confirmation that the
// log stream is actively polling. Uses a repeating AnimationController
// to fade between 30% and 100% opacity on a 1-second cycle.
// ============================================================================
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF00C9A7),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C9A7).withOpacity(0.4),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// THEME SELECTOR COMPONENTS
// ============================================================================

// ============================================================================
// THEME SELECTOR — Compact Cupertino segmented control
// ============================================================================
class _ThemeTristateToggle extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTristateToggle({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        if (v == null) return;
        onChanged(v == 0 ? ThemeMode.light : v == 1 ? ThemeMode.system : ThemeMode.dark);
      },
    );
  }
}

// ============================================================================
// VIEW TOGGLE OPTION
// ============================================================================
class _ViewToggleOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ViewToggleOption({
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C9A7) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
        ),
      ),
    );
  }
}

class NodeKillSwitch extends StatefulWidget {
  final BridgeNode node;
  final VoidCallback onToggled;
  
  const NodeKillSwitch({super.key, required this.node, required this.onToggled});

  @override
  State<NodeKillSwitch> createState() => _NodeKillSwitchState();
}

class _NodeKillSwitchState extends State<NodeKillSwitch> {
  bool _isProcessing = false;

  Future<void> _toggle() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (widget.node.isUp) {
      // STOP: always use bash for stop (pkill / systemctl stop)
      final stopCmd = widget.node.stopCmd;
      if (stopCmd != null) {
        await Process.run('bash', ['-c', stopCmd]);
      }
    } else {
      // START: use bash for systemctl; detached for Conscia is handled in ConsciaTristateToggle
      final startCmd = widget.node.startCmd;
      if (startCmd != null) {
        await Process.run('bash', ['-c', startCmd]);
      }
    }
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onToggled();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isProcessing,
      child: Opacity(
        opacity: _isProcessing ? 0.5 : 1.0,
        child: Transform.scale(
          scale: 0.72,
          child: CupertinoSwitch(
            value: widget.node.isUp,
            activeColor: const Color(0xFF00C9A7),
            trackColor: const Color(0xFFFF5F5F).withOpacity(0.5),
            onChanged: (_) => _toggle(),
          ),
        ),
      ),
    );
  }
}

class ConsciaTristateToggle extends StatefulWidget {
  final BridgeNode node;
  final VoidCallback onToggled;
  
  const ConsciaTristateToggle({super.key, required this.node, required this.onToggled});

  @override
  State<ConsciaTristateToggle> createState() => _ConsciaTristateToggleState();
}

class _ConsciaTristateToggleState extends State<ConsciaTristateToggle> {
  bool _isProcessing = false;

  Future<void> _setToggleState(int state) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (state == 0) {
      // OFF (Red) — GLOBAL SHUTDOWN: hard OS-level kill
      await Process.run('bash', ['-c', "pkill -f 'cargo run' ; pkill -f 'conscia'"]);
      widget.node.isSleeping = false;
      widget.node.isUp = false;
    } else if (state == 1) {
      // SLEEP (Orange) — OBSERVER MODEL: We ignore telemetry, but leave the process alive
      // for other potential bridge instances or background tasks.
      widget.node.isSleeping = true;
      widget.node.isUp = false;
    } else if (state == 2) {
      // ON (Green) — Start only if not already operational
      widget.node.isSleeping = false;
      
      // Check if process is already running via pgrep before starting a new one
      final check = await Process.run('pgrep', ['conscia']);
      if (check.exitCode != 0) {
        await Process.start(
          'cargo',
          ['run', '--release'],
          workingDirectory: '/home/exocrat/code/exotalk/exotalk_engine/conscia',
          mode: ProcessStartMode.detached,
          environment: {'HOME': '/home/exocrat', 'PATH': '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/exocrat/.cargo/bin'},
        );
        // Give it a moment to bind its port
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    widget.onToggled();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int currentState = 0; // 0 = OFF, 1 = SLEEP, 2 = ON
    if (widget.node.isSleeping) {
      currentState = 1;
    } else if (widget.node.isUp) {
      currentState = 2;
    }

    Color labelColor;
    if (currentState == 0) {
      labelColor = const Color(0xFFFF5F5F);
    } else if (currentState == 1) {
      labelColor = Colors.orange;
    } else {
      labelColor = const Color(0xFF00C9A7);
    }

    return IgnorePointer(
      ignoring: _isProcessing,
      child: Opacity(
        opacity: _isProcessing ? 0.5 : 1.0,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: currentState,
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDEE0E4),
          thumbColor: isDark ? const Color(0xFF3A3A3A) : Colors.white,
          padding: const EdgeInsets.all(2),
          children: {
            0: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.power_off_rounded, size: 14,
                color: currentState == 0 ? const Color(0xFFFF5F5F) : (isDark ? Colors.white70 : Colors.black54)), // Brighter
            ),
            1: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.bedtime_rounded, size: 14,
                color: currentState == 1 ? Colors.orange : (isDark ? Colors.white70 : Colors.black54)), // Brighter
            ),
            2: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.power_rounded, size: 14,
                color: currentState == 2 ? const Color(0xFF00C9A7) : (isDark ? Colors.white70 : Colors.black54)), // Brighter
            ),
          },
          onValueChanged: (v) {
            if (v != null) _setToggleState(v);
          },
        ),
      ),
    );
  }
}
