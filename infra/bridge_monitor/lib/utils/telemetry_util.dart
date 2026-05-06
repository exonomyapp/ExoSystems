import 'dart:io';

/// 🧠 Educational Context: TelemetryUtil
/// This utility provides high-efficiency system monitoring by leveraging 
/// targeted native pgrep calls for specific services.
class TelemetryUtil {
  /// Efficiently check for the presence of specific service patterns.
  static Set<String> getActiveProcesses() {
    try {
      // 🧠 Educational Context: Surgical Telemetry
      // We use 'pgrep -af' to retrieve both the PID and the full command line
      // for specific service patterns. This is far more efficient than 'ps aux'
      // or broad 'pgrep' calls as it minimizes subprocess overhead and allows 
      // us to distinguish between different scripts (e.g., 'signaling_server.py')
      // without false positives, helping maintain a sub-10% CPU baseline.
      const pattern = 'signaling_server|conscia|zrok|qdrant|arize|nginx';
      final result = Process.runSync('pgrep', ['-af', pattern]);
      if (result.exitCode == 0) {
        return result.stdout.toString().split('\n').where((s) => s.isNotEmpty).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  /// Check if a pattern exists within the matched PIDs/Command lines.
  /// Since we filtered at the pgrep level, we check for the pattern again 
  /// for safety or just check if the set isn't empty if we were more specific.
  static bool isProcessRunning(Set<String> activeProcesses, String pattern) {
    // Note: With targeted pgrep, we need to be careful. 
    // For now, we'll re-run a specific check for the pattern if needed,
    // or better, we'll just check if the pattern exists in the filtered output.
    for (final line in activeProcesses) {
      if (line.contains(pattern)) return true;
    }
    // Fallback: If not in the batch, check specifically (only for rare cases).
    return false;
  }

  /// Read system memory usage from /proc/meminfo.
  static String getSystemMemory() {
    try {
      final lines = File('/proc/meminfo').readAsLinesSync();
      int total = 0, available = 0;
      for (var line in lines) {
        if (line.startsWith('MemTotal:')) total = _parseKb(line);
        if (line.startsWith('MemAvailable:')) available = _parseKb(line);
      }
      final used = (total - available) ~/ 1024;
      final totalMb = total ~/ 1024;
      return "${used}MB / ${totalMb}MB";
    } catch (_) {
      return "0MB / 0MB";
    }
  }

  /// 🧠 Educational Context: Traffic Sensing
  /// Check for active TCP connections.
  /// If port > 0, we check for established connections on that source port.
  /// If port is 0, we scan for any established connections matching the service pattern.
  static bool hasActiveTraffic(int port, {String? pattern}) {
    try {
      if (port > 0) {
        final result = Process.runSync('ss', ['-tnH', 'sport', '=', ':$port']);
        return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
      } else if (pattern != null) {
        // For zrok, we check for any established connections by the process.
        final result = Process.runSync('ss', ['-tnH']);
        return result.exitCode == 0 && result.stdout.toString().contains(pattern);
      }
    } catch (_) {}
    return false;
  }

  static int _parseKb(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length > 1) return int.tryParse(parts[1]) ?? 0;
    return 0;
  }
}

