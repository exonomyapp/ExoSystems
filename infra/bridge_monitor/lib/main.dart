import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';

// ============================================================================
// ExoTech Bridge Monitor
//
// This application serves as a diagnostic dashboard for the "Testing Season"
// infrastructure. It dynamically discovers local nodes (Signaling Relay,
// Conscia Beacon, and Public Proxy) to provide a real-time health overview
// of the Sovereign Mesh environment without relying on hardcoded IPs or ports.
// ============================================================================

void main() {
  runApp(const ExoTechBridgeApp());
}

class ExoTechBridgeApp extends StatelessWidget {
  const ExoTechBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the "Premium Sovereign" aesthetic theme.
    // Deep matte blacks and muted teals replace stark neon colors to ensure
    // high legibility and a modern, professional appearance suitable for
    // extended monitoring sessions.
    return MaterialApp(
      title: 'ExoTech Bridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Deep matte black
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9A7), // Muted teal indicator color
          brightness: Brightness.dark,
          surface: const Color(0xFF141414), // Slightly elevated surface for cards
        ),
        // Applying the Outfit Google Font for modern, geometric typography
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
  // UI State
  bool _isGridView = true; // Toggles between Card and Row/List views
  
  // Dynamic Environment Data
  String _localHost = "DISCOVERING...";
  List<BridgeNode> _nodes = [];
  
  // Polling State
  Timer? _refreshTimer;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initDiscovery();
    // Establish a 5-second polling interval to continuously verify node health
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _performScan());
  }

  // Identify the physical host running this monitor
  Future<void> _initDiscovery() async {
    setState(() {
      _localHost = Platform.localHostname.toUpperCase();
    });
    await _performScan();
  }

  // The core telemetry loop: Scans the local environment to detect expected services
  Future<void> _performScan() async {
    if (_isScanning) return; // Prevent overlapping scans
    _isScanning = true;

    final List<BridgeNode> scannedNodes = [];

    // 1. Signaling Server: Required for WebRTC peer discovery in the browser demo
    // Standard port: 8080
    final signalingUp = await _checkPort(8080);
    scannedNodes.add(BridgeNode(
      name: "Signaling Relay",
      machine: _localHost,
      role: "WebRTC Handshake Bridge",
      port: 8080,
      isUp: signalingUp,
      icon: Icons.hub_outlined,
    ));

    // 2. Conscia Beacon: The core P2P rust-based node for the Sovereign Mesh
    // Standard port: 3000
    final beaconUp = await _checkPort(3000);
    scannedNodes.add(BridgeNode(
      name: "Conscia Beacon",
      machine: _localHost,
      role: "P2P Mesh Node (Sovereign)",
      port: 3000,
      isUp: beaconUp,
      icon: Icons.radar_outlined,
    ));

    // 3. Public Proxy: The zrok tunnel exposing the local mesh to exotalk.tech
    // We check for the 'zrok' process rather than a specific local port
    final zrokUp = await _checkProcess("zrok");
    scannedNodes.add(BridgeNode(
      name: "Public Proxy",
      machine: "ZROK INFRA",
      role: "External Gateway (exotalk.tech)",
      port: 0, // Port not applicable for process-based check in this view
      isUp: zrokUp,
      icon: Icons.public_outlined,
    ));

    // Update UI safely
    if (mounted) {
      setState(() {
        _nodes = scannedNodes;
        _isScanning = false;
      });
    }
  }

  // Utility to check if a specific TCP port is listening locally
  Future<bool> _checkPort(int port) async {
    try {
      final s = await Socket.connect('localhost', port, timeout: const Duration(milliseconds: 500));
      s.destroy();
      return true; // Connection successful; service is up
    } catch (_) {
      return false; // Connection refused or timed out; service is down
    }
  }

  // Utility to check if a process with a specific name is running using 'pgrep'
  Future<bool> _checkProcess(String name) async {
    try {
      final res = await Process.run('pgrep', [name]);
      return res.exitCode == 0; // pgrep returns 0 if at least one process matches
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // View Toggle Control: Allows the user to switch between Grid and List representations
          IconButton(
            tooltip: _isGridView ? "Switch to List View" : "Switch to Grid View",
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, 
                 color: const Color(0xFF00C9A7).withOpacity(0.8)),
            onPressed: () => setState(() => _isGridView = !_isGridView),
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
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  // Render the appropriate view based on toggle state
                  child: _isGridView ? _buildGrid() : _buildList(),
                ),
          ),
        ],
      ),
    );
  }

  // Displays the current host environment and polling rate
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

  // Renders nodes as large, elevated cards (optimized for high-resolution displays)
  Widget _buildGrid() {
    return GridView.builder(
      key: const ValueKey("grid"),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 32,
        mainAxisSpacing: 32,
        childAspectRatio: 1.4,
      ),
      itemCount: _nodes.length,
      itemBuilder: (context, i) => NodeCard(node: _nodes[i]),
    );
  }

  // Renders nodes as compact, dense rows (optimized for scanning detailed information)
  Widget _buildList() {
    return ListView.separated(
      key: const ValueKey("list"),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      itemCount: _nodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, i) => NodeRow(node: _nodes[i]),
    );
  }
}

// ============================================================================
// Data Models & Component Definitions
// ============================================================================

class BridgeNode {
  final String name;
  final String machine;
  final String role;
  final int port;
  final IconData icon;
  bool isUp;

  BridgeNode({
    required this.name, 
    required this.machine, 
    required this.role, 
    required this.port, 
    required this.icon,
    this.isUp = false,
  });
}

// Visual representation for Grid View
class NodeCard extends StatelessWidget {
  final BridgeNode node;
  const NodeCard({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    // Dynamic color coding based on health status
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    final surfaceColor = const Color(0xFF141414);
    final textMuted = const Color(0xFFA0A0A0);
    
    return Container(
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
    );
  }
}

// Visual representation for List View (maintains feature parity with NodeCard)
class NodeRow extends StatelessWidget {
  final BridgeNode node;
  const NodeRow({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final statusColor = node.isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    final textMuted = const Color(0xFFA0A0A0);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          Icon(node.icon, color: statusColor.withOpacity(0.7), size: 24),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900, 
                    fontSize: 15, 
                    color: const Color(0xFFD0D0D0),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node.role,
                  style: GoogleFonts.outfit(fontSize: 12, color: textMuted.withOpacity(0.6)),
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
                const SizedBox(height: 4),
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
                fontSize: 13, 
                fontWeight: FontWeight.bold, 
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
          _StatusIndicator(isUp: node.isUp),
        ],
      ),
    );
  }
}

// Reusable glowing status dot indicator
class _StatusIndicator extends StatelessWidget {
  final bool isUp;
  const _StatusIndicator({required this.isUp});

  @override
  Widget build(BuildContext context) {
    final statusColor = isUp ? const Color(0xFF00C9A7) : const Color(0xFFFF5F5F);
    return Container(
      width: 14,
      height: 14,
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
