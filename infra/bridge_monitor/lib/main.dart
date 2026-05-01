import 'package:flutter/material.dart';
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

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExoTech Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9A7),
          brightness: Brightness.dark,
          surface: const Color(0xFF141414),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(color: const Color(0xFFD0D0D0), fontWeight: FontWeight.w900),
          bodyLarge: GoogleFonts.outfit(color: const Color(0xFFB0B0B0)),
          bodyMedium: GoogleFonts.outfit(color: const Color(0xFFA0A0A0)),
        ),
      ),
      home: const BridgeMonitorScreen(),
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
  
  Timer? _refreshTimer;
  bool _isScanning = false;
  File? _sessionLogFile;

  @override
  void initState() {
    super.initState();
    _initStorage();
    _initDiscovery();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _performScan());
  }

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
      BridgeNode(id: "signaling-1", name: "Signaling Relay", machine: _localHost, role: "WebRTC Handshake Bridge", port: 8080, icon: Icons.hub_outlined),
      BridgeNode(id: "beacon-1", name: "Conscia Beacon", machine: _localHost, role: "P2P Mesh Node (Sovereign)", port: 3000, icon: Icons.radar_outlined),
      BridgeNode(id: "proxy-1", name: "Public Proxy", machine: "ZROK INFRA", role: "External Gateway (exotalk.tech)", port: 0, icon: Icons.public_outlined),
    ];
    await _performScan();
  }

  Future<void> _performScan() async {
    if (_isScanning) return;
    _isScanning = true;

    for (var node in _nodes) {
      if (node.id.startsWith("signaling")) {
        node.isUp = await _checkPort(node.port);
        final logs = await _fetchJournalctlLogs("exotalk-signaling");
        _updateLogs(node, logs);
      } else if (node.id.startsWith("beacon")) {
        node.isUp = await _checkPort(node.port);
        final logs = await _fetchTailLogs("/home/exocrat/conscia.log");
        _updateLogs(node, logs);
      } else if (node.id.startsWith("proxy")) {
        node.isUp = await _checkProcess("zrok");
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
    if (fetchedLogs.isNotEmpty) {
      // Find new logs that haven't been captured yet
      final newLogs = fetchedLogs.where((l) => !node.logs.contains(l)).toList();
      if (newLogs.isNotEmpty) {
        node.logs.addAll(newLogs);
        _appendLogToFile(node.id, newLogs);
      }
    }
  }

  Future<List<String>> _fetchJournalctlLogs(String service) async {
    try {
      final res = await Process.run('journalctl', ['-u', service, '-n', '50', '--no-pager']);
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

  Future<bool> _checkProcess(String name) async {
    try {
      final res = await Process.run('pgrep', [name]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleIsolation(String nodeId) {
    setState(() {
      if (_isolatedNodeId == nodeId) {
        _isolatedNodeId = null; // Un-isolate
      } else {
        _isolatedNodeId = nodeId; // Isolate new
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Clicking the background removes isolation
      onTap: () {
        if (_isolatedNodeId != null) {
          setState(() => _isolatedNodeId = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.waves, color: Color(0xFF00C9A7), size: 28),
              const SizedBox(width: 16),
              Text(
                "EXOTECH BRIDGE",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  fontSize: 22,
                  color: const Color(0xFFD0D0D0),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _isGridView ? "Switch to List View" : "Switch to Grid View",
              icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, 
                   color: const Color(0xFF00C9A7).withOpacity(0.8)),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                  _isolatedNodeId = null; // Reset isolation on view switch
                });
              },
            ),
            const SizedBox(width: 24),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderStatus(),
            Expanded(
              child: _nodes.isEmpty 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
                : _isGridView ? _buildGrid() : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00C9A7).withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.2)),
        ),
        child: Text(
          "ACTIVE TELEMETRY | NODE: $_localHost | REFRESH: 5S",
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: const Color(0xFF00C9A7).withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // --- Grid / Card View Logic ---

  Widget _buildGrid() {
    // If isolated, we show the card in top left, and log panel on right.
    if (_isolatedNodeId != null) {
      final isolatedNode = _nodes.firstWhere((n) => n.id == _isolatedNodeId);
      return Stack(
        children: [
          // The background grid (faded)
          Opacity(
            opacity: 0.1,
            child: _buildStandardGrid(),
          ),
          // The isolated foreground
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Isolated Card
                SizedBox(
                  width: 350,
                  height: 250,
                  child: GestureDetector(
                    onTap: () {}, // Consume tap so it doesn't close
                    child: NodeCard(
                      node: isolatedNode,
                      onTap: () => _toggleIsolation(isolatedNode.id),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Slide-out Log Viewer
                Expanded(
                  child: GestureDetector(
                    onTap: () {}, // Consume tap
                    child: LogViewer(node: isolatedNode),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return _buildStandardGrid();
    }
  }

  Widget _buildStandardGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 32,
        mainAxisSpacing: 32,
        childAspectRatio: 1.4,
      ),
      itemCount: _nodes.length,
      itemBuilder: (context, i) => NodeCard(
        node: _nodes[i],
        onTap: () => _toggleIsolation(_nodes[i].id),
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
              ),
              if (isExpanded)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 300, // Accordion height
                  margin: const EdgeInsets.only(top: 8),
                  child: LogViewer(node: node),
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
  bool isUp;
  List<String> logs;

  BridgeNode({
    required this.id,
    required this.name, 
    required this.machine, 
    required this.role, 
    required this.port, 
    required this.icon,
    this.isUp = false,
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              color: const Color(0xFF141414),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, color: const Color(0xFF00C9A7).withOpacity(0.8), size: 16),
                const SizedBox(width: 8),
                Text("SYSTEM LOGS: ${widget.node.id}", 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
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
  const NodeCard({super.key, required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    final surfaceColor = const Color(0xFF141414);
    final textMuted = const Color(0xFFA0A0A0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(node.icon, color: statusColor.withOpacity(0.8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: const Color(0xFFD0D0D0),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                _StatusIndicator(isUp: node.isUp),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              node.isUp ? "OPERATIONAL" : "INACTIVE",
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: statusColor,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            Text(
              "SOURCE: ${node.machine}",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              node.role,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: textMuted.withOpacity(0.7),
              ),
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
  const NodeRow({super.key, required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    final textMuted = const Color(0xFFA0A0A0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(8), // More compact
          border: Border.all(color: statusColor.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // More compact
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
                      color: const Color(0xFFD0D0D0),
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
            _StatusIndicator(isUp: node.isUp),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isUp;
  const _StatusIndicator({required this.isUp});

  @override
  Widget build(BuildContext context) {
    final statusColor = isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    return Container(
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
    );
  }
}
