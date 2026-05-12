import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';
import 'providers/blueprint_provider.dart';
import 'federation/federation_view.dart';
import 'services/services_screen.dart';
import 'services/geographic_context_screen.dart';
class ConSoul extends ConsumerStatefulWidget {
  const ConSoul({super.key});

  @override
  ConsumerState<ConSoul> createState() => _ConSoulState();
}

class _ConSoulState extends ConsumerState<ConSoul> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final identityState = ref.watch(identityProvider);

    // 🧠 EDUCATIONAL CONTEXT: Progressive Disclosure Architecture
    // The NavigationRail dynamically rebuilds based on the capabilitiesProvider.
    // Rather than rigid "admin levels", the interface seamlessly reveals authorized
    // controls in real time as the user's Meadowcap capability profile evolves.
    // This allows for dynamic SDUI adaptation without requiring an application restart.
    final capabilities = ref.watch(capabilitiesProvider);

    final List<NavigationRailDestination> destinations = capabilities.map((cap) {
      switch (cap) {
        case ConsoulCapability.operationalPulse:
          return const NavigationRailDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: Text('Operational Pulse'),
          );
        case ConsoulCapability.authorityMatrix:
          return const NavigationRailDestination(
            icon: Icon(Icons.manage_accounts_outlined),
            selectedIcon: Icon(Icons.manage_accounts),
            label: Text('Authority Matrix'),
          );
        case ConsoulCapability.sovereignGovernance:
          return const NavigationRailDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: Text('Sovereign Governance'),
          );
        case ConsoulCapability.federationAdministration:
          return const NavigationRailDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub),
            label: Text('Federation'),
          );
        case ConsoulCapability.serviceAdministration:
          return const NavigationRailDestination(
            icon: Icon(Icons.settings_suggest_outlined),
            selectedIcon: Icon(Icons.settings_suggest),
            label: Text('Services'),
          );
        case ConsoulCapability.geographicContext:
          return const NavigationRailDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: Text('Geographic'),
          );
      }
    }).toList();

    // Build the body based on the dynamically authorized capability at the selected index.
    Widget body;
    if (_selectedIndex >= capabilities.length) {
      body = _buildPulseView();
    } else {
      switch (capabilities[_selectedIndex]) {
        case ConsoulCapability.operationalPulse:
          body = _buildPulseView();
          break;
        case ConsoulCapability.authorityMatrix:
          body = _buildAuthorityView();
          break;
        case ConsoulCapability.sovereignGovernance:
          body = _buildGovernanceView();
          break;
        case ConsoulCapability.federationAdministration:
          body = const FederationView();
          break;
        case ConsoulCapability.serviceAdministration:
          body = const ServicesScreen();
          break;
        case ConsoulCapability.geographicContext:
          body = const GeographicContextScreen();
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ConSoul'),
        actions: [
          _buildIdentityIndicator(identityState),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex >= destinations.length ? 0 : _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityIndicator(IdentityState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (state.activeDid != null) {
      final shortDid = '${state.activeDid!.substring(0, 8)}...';
      return ActionChip(
        avatar: const Icon(Icons.verified_user, size: 16),
        label: Text(shortDid),
        onPressed: () {
          // Open Identity Vault
        },
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.vpn_key),
      label: const Text('Establish Authority'),
      onPressed: () {
        _showMeadowcapAuth();
      },
    );
  }

  void _showMeadowcapAuth() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Meadowcap Authentication'),
          content: const Text('Secure cryptographic identity verification via exoauth.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  Widget _buildPulseView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Operational Pulse', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Awaiting diagnostic telemetry and network connectivity feeds.'),
          // The 5-stage horizontal monitor will reside here.
        ],
      ),
    );
  }

  Widget _buildAuthorityView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Authority Matrix', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Cryptographic node orchestration and service legislation controls.'),
        ],
      ),
    );
  }

  Widget _buildGovernanceView() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sovereign Governance', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Meadowcap capability management and mesh membership governance.'),
        ],
      ),
    );
  }
}
