// =============================================================================
// verified_links_card.dart — Verification Badge Display
// =============================================================================
//
// Displays the user's currently verified external identity links (e.g.,
// "GitHub ✓", "Mastodon ✓"). Each link shows the platform label, a truncated
// URL, and an external link icon that opens the proof URL in the system browser.
//
// Only verified links (isVerified == true) are shown. If there are no verified
// links, the widget renders as an invisible SizedBox.shrink().
//
// Supports a `isCompact` mode (hides the section header) for inline use.
// Used in: AccountManagerModal's profile section.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:exoauth/exoauth.dart';
import '../../src/theme.dart' hide NameRecord, VerifiedLink;

class VerifiedLinksCard extends StatelessWidget {
  final List<VerifiedLink> links;
  final bool isCompact;

  const VerifiedLinksCard({
    super.key,
    required this.links,
    this.isCompact = false,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifiedLinks = links.where((l) => l.isVerified).toList();
    if (verifiedLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              "Verified Identities",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: ConsciaTheme.muted(context),
              ),
            ),
          ),
          SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ConsciaTheme.background(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ConsciaTheme.border(context)),
          ),
          child: Column(
            children: verifiedLinks.map((link) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link.platformLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      _truncateUrl(link.url),
                      style: TextStyle(
                        fontSize: 11,
                        color: ConsciaTheme.muted(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () => _launchUrl(link.url),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.externalLink,
                          size: 14,
                          color: ConsciaTheme.accent(context),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _truncateUrl(String url) {
    final uri = Uri.parse(url);
    String display = uri.host + uri.path;
    if (display.length > 25) {
      return "${display.substring(0, 22)}...";
    }
    return display;
  }
}
