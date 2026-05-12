import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// 🧠 EDUCATIONAL CONTEXT: The Conscia Data Bridge
// This provider layer implements the "API Parity" directive. Every action
// taken in the ConSoul UI is translated into an HTTP request to the 
// Conscia daemon, ensuring the interface remains a stateless reflection
// of the underlying node's cryptographic and operational reality.

final baseUrl = 'http://127.0.0.1:3000';

final topologyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await http.get(Uri.parse('$baseUrl/api/federation/topology'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  throw Exception('Failed to load topology');
});

final petitionsProvider = FutureProvider<List<String>>((ref) async {
  final response = await http.get(Uri.parse('$baseUrl/api/governance/petitions'));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => e.toString()).toList();
  }
  throw Exception('Failed to load petitions');
});

final discoveryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await http.get(Uri.parse('$baseUrl/api/discovery'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  throw Exception('Failed to load discovery');
});

final consciaActionProvider = Provider((ref) => ConsciaActions());

class ConsciaActions {
  Future<void> authorizePeer(String id, String role) async {
    await http.post(
      Uri.parse('$baseUrl/api/governance/authorize'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': id, 'role': role}),
    );
  }
}
