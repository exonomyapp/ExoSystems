// =============================================================================
// name_history_card.dart — Archived Display Name Timeline
// =============================================================================
//
// A read-only timeline widget showing the user's previous display names.
// Each entry includes the retired date and any verified links that were
// active under that name. This provides a transparent audit trail so that
// peers can trace the identity lineage of a did:peer across name changes.
//
// Used in: AccountManagerModal's profile section.
// Data source: UserProfile.nameHistory (from Rust IdentityVault.name_history).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:exoauth/exoauth.dart';
import '../../src/theme.dart' hide NameRecord, VerifiedLink;

class NameHistoryCard extends StatelessWidget {
  final List<NameRecord> history;

  const NameHistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Name History",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: ConsciaTheme.muted(context),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ConsciaTheme.background(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ConsciaTheme.border(context)),
          ),
          child: Column(
            children: history.reversed.map((record) {
              final retiredDate = DateFormat.yMMMd().format(
                DateTime.fromMillisecondsSinceEpoch(record.retiredAtMs),
              );
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ConsciaTheme.muted(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                record.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "retired $retiredDate",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ConsciaTheme.muted(context),
                                ),
                              ),
                            ],
                          ),
                          if (record.verifiedLinks.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: record.verifiedLinks.map((link) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      link.isVerified ? LucideIcons.shieldCheck : LucideIcons.shield,
                                      size: 10,
                                      color: link.isVerified ? Colors.green : ConsciaTheme.muted(context),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      link.platformLabel,
                                      style: TextStyle(fontSize: 10, color: ConsciaTheme.muted(context)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ],
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
}
