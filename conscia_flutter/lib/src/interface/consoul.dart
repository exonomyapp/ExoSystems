import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exoauth/exoauth.dart';

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
    final isAuthenticated = identityState.activeDid != null;

    // The interface dynamically adapts based on established Meadowcap authority.
    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.monitor_heart_outlined),
        selectedIcon: Icon(Icons.monitor_heart),
        label: Text('Operational Pulse'),
      ),
      if (isAuthenticated)
        const NavigationRailDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: Text('Authority Matrix'),
        ),
      if (isAuthenticated)
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Sovereign Governance'),
        ),
    ];

    // Build the body based on the selected index.
    Widget body;
    if (_selectedIndex == 0) {
      body = _buildPulseView();
    } else if (_selectedIndex == 1 && isAuthenticated) {
      body = _buildAuthorityView();
    } else if (_selectedIndex == 2 && isAuthenticated) {
      body = _buildGovernanceView();
    } else {
      body = _buildPulseView();
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
