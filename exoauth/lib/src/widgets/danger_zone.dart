// =============================================================================
// danger_zone.dart — GitHub-Identical Danger Zone Component
// =============================================================================
// Replicates the exact layout and styling of GitHub's Primer "Danger zone"
// section found on repository/account settings pages:
//   • Heading above the box in danger-red
//   • Rounded container with a muted danger border
//   • Rows separated by internal dividers
//   • Each row: title + description on the left, action button on the right
// =============================================================================
import 'package:flutter/material.dart';
import '../theme.dart';

/// A single destructive action to display inside a [DangerZone].
class DangerZoneItem {
  /// Bold title displayed on the left (e.g. "Delete this repository").
  final String title;

  /// Muted description below the title.
  final String description;

  /// Label on the destructive button (e.g. "Delete").
  final String buttonLabel;

  /// Callback fired when the button is pressed.
  final VoidCallback onPressed;

  const DangerZoneItem({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });
}

/// A GitHub-identical "Danger zone" section.
///
/// Usage:
/// ```dart
/// DangerZone(
///   scale: scale,
///   items: [
///     DangerZoneItem(
///       title: "Discard Identity",
///       description: "Permanently wipes all local secrets and history.",
///       buttonLabel: "Discard Identity",
///       onPressed: () { /* ... */ },
///     ),
///   ],
/// )
/// ```
class DangerZone extends StatelessWidget {
  final double scale;
  final List<DangerZoneItem> items;

  const DangerZone({
    super.key,
    required this.scale,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading — outside the box, matching GitHub
        Padding(
          padding: EdgeInsets.only(left: 2.0 * scale, bottom: 8.0 * scale),
          child: Text(
            "Danger zone",
            style: ConsciaTheme.subHeadingStyle(context, scale).copyWith(
              color: ConsciaTheme.error(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // The bordered container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0 * scale),
            border: Border.all(
              color: ConsciaTheme.dangerBorder(context),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0 * scale),
            child: Column(
              children: List.generate(items.length, (index) {
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: ConsciaTheme.dangerBorder(context),
                      ),
                    _DangerZoneRow(
                      item: items[index],
                      scale: scale,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single row inside the danger zone container.
/// Mirrors GitHub's layout: [title + description] ←→ [button].
class _DangerZoneRow extends StatelessWidget {
  final DangerZoneItem item;
  final double scale;

  const _DangerZoneRow({required this.item, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0 * scale,
        vertical: 16.0 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: ConsciaTheme.bodyStyle(context, scale).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.0 * scale),
                Text(
                  item.description,
                  style: ConsciaTheme.captionStyle(context, scale).copyWith(
                    fontSize: 12.0 * scale,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.0 * scale),
          // Right: destructive button
          _DangerButton(
            label: item.buttonLabel,
            onPressed: item.onPressed,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

/// A GitHub-identical danger button: outlined with danger-red border and text,
/// fills solid danger-red with white text on hover.
class _DangerButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final double scale;

  const _DangerButton({
    required this.label,
    required this.onPressed,
    required this.scale,
  });

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dangerColor = ConsciaTheme.error(context);
    final dangerBorderColor = ConsciaTheme.dangerBorder(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: OutlinedButton(
        onPressed: widget.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _isHovered ? Colors.white : dangerColor,
          backgroundColor: _isHovered ? dangerColor : Colors.transparent,
          side: BorderSide(
            color: _isHovered ? dangerColor : dangerBorderColor,
            width: 1.0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16.0 * widget.scale,
            vertical: 8.0 * widget.scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0 * widget.scale),
          ),
          textStyle: TextStyle(
            fontSize: 12.0 * widget.scale,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: Text(widget.label),
      ),
    );
  }
}
