import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';

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
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FFCC),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
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
  String _localHost = "Checking...";
  
  final List<BridgeNode> _nodes = [
    BridgeNode(
      name: "Signaling Server",
      machine: "EXONOMY",
      role: "WebRTC Handshake Relay",
      port: 8080,
    ),
    BridgeNode(
      name: "Sovereign Mesh Node",
      machine: "EXONOMY",
      role: "Conscia Beacon (P2P)",
      port: 3000,
    ),
    BridgeNode(
      name: "Public Proxy",
      machine: "zrok INFRA",
      role: "Public Gateway (exotalk.tech)",
      port: 0,
      processName: "zrok",
    ),
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initLocalInfo();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  Future<void> _initLocalInfo() async {
    _localHost = Platform.localHostname.toUpperCase();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    for (var node in _nodes) {
      if (node.port > 0) {
        try {
          final s = await Socket.connect('localhost', node.port, timeout: const Duration(milliseconds: 500));
          node.isUp = true;
          s.destroy();
        } catch (_) {
          node.isUp = false;
        }
      } else if (node.processName != null) {
        try {
          final res = await Process.run('pgrep', [node.processName!]);
          node.isUp = res.exitCode == 0;
        } catch (_) {
          node.isUp = false;
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.waves, color: Color(0xFF00FFCC), size: 24),
            const SizedBox(width: 12),
            Text(
              "EXOTECH BRIDGE",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 20,
                color: const Color(0xFFD0D0D0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xFF00FFCC)),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Text(
              "SYSTEMS STATUS | LOCAL NODE: $_localHost",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: const Color(0xFF00FFCC).withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: _isGridView ? _buildGrid() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 30,
        mainAxisSpacing: 30,
        childAspectRatio: 1.3,
      ),
      itemCount: _nodes.length,
      itemBuilder: (context, i) => NodeCard(node: _nodes[i]),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      itemCount: _nodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => NodeRow(node: _nodes[i]),
    );
  }
}

class NodeCard extends StatelessWidget {
  final BridgeNode node;
  const NodeCard({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final statusColor = node.isUp ? const Color(0xFF00FFCC) : const Color(0xFFFF5555);
    final softWhite = const Color(0xFFE0E0E0);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                node.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: softWhite,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 6)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.isUp ? "OPERATIONAL" : "INACTIVE",
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: statusColor,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            node.machine,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB0B0B0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.role,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFFA0A0A0),
            ),
          ),
        ],
      ),
    );
  }
}

class NodeRow extends StatelessWidget {
  final BridgeNode node;
  const NodeRow({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final statusColor = node.isUp ? const Color(0xFF00FFCC) : const Color(0xFFFF5555);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Text(
              node.name.toUpperCase(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFFE0E0E0)),
            ),
          ),
          Expanded(
            child: Text(
              node.isUp ? "ACTIVE" : "OFFLINE",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, color: statusColor),
            ),
          ),
          Expanded(
            child: Text(
              node.machine,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFA0A0A0)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              node.role,
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF808080)),
            ),
          ),
        ],
      ),
    );
  }
}

class BridgeNode {
  final String name;
  final String machine;
  final String role;
  final int port;
  final String? processName;
  bool isUp = false;

  BridgeNode({required this.name, required this.machine, required this.role, required this.port, this.processName});
}
