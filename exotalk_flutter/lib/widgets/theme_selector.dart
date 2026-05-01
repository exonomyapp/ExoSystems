import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../src/theme.dart';

/// A premium tristate control for switching between Light, Dark, and System theme modes.
/// Adheres to the "Solid Identity" design system with high-contrast borders and tactile feedback.
class ThemeSelector extends ConsumerWidget {
  final double scale;
  const ThemeSelector({super.key, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.0 * scale, bottom: 8.0 * scale),
          child: Text(
            "APPEARANCE",
            style: ConsciaTheme.captionStyle(context, scale).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: ConsciaTheme.muted(context),
              fontSize: 10 * scale,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(4.0 * scale),
          decoration: BoxDecoration(
            color: ConsciaTheme.inputFill(context),
            borderRadius: BorderRadius.circular(12.0 * scale),
            border: Border.all(color: ConsciaTheme.border(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  icon: LucideIcons.sun,
                  label: "Light",
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
                  scale: scale,
                ),
              ),
              Expanded(
                child: _ThemeOption(
                  icon: LucideIcons.moon,
                  label: "Dark",
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
                  scale: scale,
                ),
              ),
              Expanded(
                child: _ThemeOption(
                  icon: LucideIcons.monitor,
                  label: "System",
                  isSelected: currentMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
                  scale: scale,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.0 * scale),
        decoration: BoxDecoration(
          color: isSelected ? ConsciaTheme.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0 * scale),
          border: Border.all(
            color: isSelected ? ConsciaTheme.accent(context) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.0 * scale,
              color: isSelected ? ConsciaTheme.accent(context) : ConsciaTheme.muted(context),
            ),
            SizedBox(height: 4.0 * scale),
            Text(
              label,
              style: ConsciaTheme.captionStyle(context, scale).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : ConsciaTheme.muted(context),
                fontSize: 11 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact, icon-only version of the theme selector designed for the Sidebar.
/// Uses a 3-position horizontal sliding layout with icons for Light, System, and Dark modes.
class ThemeTristateToggle extends ConsumerWidget {
  final double scale;
  const ThemeTristateToggle({super.key, required this.scale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    
    return Container(
      padding: EdgeInsets.all(2.0 * scale),
      decoration: BoxDecoration(
        color: ConsciaTheme.inputFill(context),
        borderRadius: BorderRadius.circular(24.0 * scale),
        border: Border.all(color: ConsciaTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactOption(
            icon: LucideIcons.sun,
            isSelected: currentMode == ThemeMode.light,
            onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.light),
            scale: scale,
          ),
          _CompactOption(
            icon: LucideIcons.monitor,
            isSelected: currentMode == ThemeMode.system,
            onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.system),
            scale: scale,
          ),
          _CompactOption(
            icon: LucideIcons.moon,
            isSelected: currentMode == ThemeMode.dark,
            onTap: () => ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark),
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _CompactOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;

  const _CompactOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(6.0 * scale),
        decoration: BoxDecoration(
          color: isSelected ? ConsciaTheme.accent(context) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14.0 * scale,
          color: isSelected ? Colors.white : ConsciaTheme.muted(context),
        ),
      ),
    );
  }
}
