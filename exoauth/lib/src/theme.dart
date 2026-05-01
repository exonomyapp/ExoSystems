import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conscia Design System Tokens
/// 
/// These colors and styles are derived from the Conscia Beacon Dashboard
/// to ensure a unified "Sovereign" aesthetic across the exosystem.
class ConsciaTheme {
  // Dark Palette (Internal constants)
  static const Color _darkBackground = Color(0xFF0D1117);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkAccent = Color(0xFF238636); 
  static const Color _darkBorder = Color(0xFF30363D);
  static const Color _darkText = Color(0xCCE6EDF3); // 80% intensity
  static const Color _darkMuted = Color(0xFFA0A9B4); 
  static const Color _error = Color(0xFFF85149); // GitHub Primer: danger fg (dark)

  // Elevated Surface Tokens (Internal)
  static const Color _darkSurfaceElevated = Color(0xFF1C2128); 
  static const Color _darkBorderStrong = Color(0xFF444C56); 

  // Light Palette (Internal constants)
  static const Color _lightBackground = Color(0xFFF6F8FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBorder = Color(0xFFD0D7DE);
  static const Color _lightBorderStrong = Color(0xFF8B949E);
  static const Color _lightText = Color(0xFF1F2328);
  static const Color _lightMuted = Color(0xFF636C76); // GitHub-style gray
  static const Color _lightAccent = Color(0xFF1F883D);

  // Solid State Tokens
  static const Color _darkHover = Color(0xFF21262D);
  static const Color _lightHover = Color(0xFFF0F2F5);

  // Theme-aware Getters (Require BuildContext)
  static Color background(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color border(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color text(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color muted(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _darkMuted : _lightMuted;
  static Color error(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF85149) : const Color(0xFFCF222E);
  static Color warning(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFD29922) : const Color(0xFFBF8700);

  // GitHub Primer Danger Zone tokens
  static Color dangerBorder(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFFDA3633) : const Color(0xFFD1242F);
  static Color dangerBg(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF3B1818) : const Color(0xFFFFEBEB);
  
  static Color warningBg(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF332A16) : const Color(0xFFFFF8E5);
  static Color accentBg(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF14291B) : const Color(0xFFEAF5EB);
  
  static Color surfaceElevated(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _darkSurfaceElevated : _lightSurface;
  static Color borderStrong(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _darkBorderStrong : _lightBorderStrong;
  static Color inputFill(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Color(0xFF010409) : Colors.white;
  static Color hover(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _darkHover : _lightHover;
  static Color selection(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Color(0xFF21262D) : Color(0xFFEBEDF0);
  static Color accentDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Color(0xFF14452F) : Color(0xFFD1E4DD);
  
  static Color meshInbound(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF50C878) : const Color(0xFF059669);
  static Color meshOutbound(BuildContext context) => accent(context);

  /// Centralized gradient for the main workspace and onboarding flows.
  static List<Color> mainGradient(BuildContext context) => Theme.of(context).brightness == Brightness.dark 
      ? [background(context), Color(0xFF0F172A)] 
      : [background(context), Color(0xFFE2E8F0)];

  // Static legacy/accent constants
  static const Color gold = Color(0xFFD4AF37);
  static const Color emerald = Color(0xFF50C878);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _darkAccent,
        onPrimary: Color(0xCCF0F6FC), // 80% intensity
        secondary: Color(0xFF58A6FF), 
        surface: _darkSurface,
        onSurface: _darkText,
        outline: _darkBorder,
        error: _error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: const Color(0xCCF0F6FC), fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: const Color(0xCCF0F6FC)),
          bodyMedium: TextStyle(color: const Color(0xCCF0F6FC)),
          bodySmall: TextStyle(color: _darkMuted),
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _darkBorderStrong, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _darkBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xCCF0F6FC);
          return _darkMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkAccent;
          return _darkBorder;
        }),
        trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _lightAccent,
        onPrimary: Colors.white,
        secondary: Color(0xFF0969DA),
        surface: _lightSurface,
        onSurface: _lightText,
        outline: _lightBorder,
        error: _error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: _lightText, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: _lightText),
          bodyMedium: TextStyle(color: _lightText),
          bodySmall: TextStyle(color: _lightMuted),
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _lightBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _lightBorderStrong, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _lightBorder,
        thickness: 1,
      ),
    );
  }
  
  // Typography helpers that respect scale and context
  static TextStyle headingStyle(BuildContext context, double scale) => GoogleFonts.inter(
    fontSize: 21.0 * scale,
    fontWeight: FontWeight.w700,
    color: text(context),
    letterSpacing: -0.5,
  );

  static TextStyle subHeadingStyle(BuildContext context, double scale) => GoogleFonts.inter(
    fontSize: 17.5 * scale,
    fontWeight: FontWeight.w600,
    color: text(context),
  );

  static TextStyle bodyStyle(BuildContext context, double scale) => GoogleFonts.inter(
    fontSize: 16.2 * scale,
    color: text(context),
  );

  static TextStyle captionStyle(BuildContext context, double scale) => GoogleFonts.inter(
    fontSize: 14.5 * scale,
    color: muted(context),
  );

  static TextStyle versionStyle(BuildContext context, double scale) => TextStyle(
    fontFamily: 'Courier',
    fontSize: 12.0 * scale,
    color: muted(context),
  );

  // Spacing & Padding Tokens
  static double cardPadding(double scale) => 24.0 * scale;
  static double elementSpacing(double scale) => 16.0 * scale;
  static double headerPaddingVertical(double scale) => 32.0 * scale;
  static double headerPaddingHorizontal(double scale) => 24.0 * scale;

  // Premium Decorations (Solid only)
  static BoxDecoration premiumCardDecoration(BuildContext context, double scale) => BoxDecoration(
    color: surface(context),
    borderRadius: BorderRadius.circular(24.0 * scale),
    border: Border.all(color: border(context), width: 1.5),
    boxShadow: Theme.of(context).brightness == Brightness.light ? [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: Offset(0, 10),
      )
    ] : null,
  );

  static BoxDecoration solidDecoration(BuildContext context, {Color? color, double radius = 0, bool hasBorder = true}) {
    return BoxDecoration(
      color: color ?? surface(context),
      borderRadius: BorderRadius.circular(radius),
      border: hasBorder ? Border.all(color: border(context)) : null,
    );
  }

  static InputDecoration inputDecoration(BuildContext context, String hint, double scale) => InputDecoration(
    hintText: hint,
    hintStyle: captionStyle(context, scale),
    filled: true,
    fillColor: inputFill(context),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.0 * scale, vertical: 12.0 * scale),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0 * scale),
      borderSide: BorderSide(color: border(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0 * scale),
      borderSide: BorderSide(color: accent(context)),
    ),
  );
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences? prefs;

  ThemeModeNotifier(this.prefs) : super(_loadTheme(prefs));

  static ThemeMode _loadTheme(SharedPreferences? prefs) {
    if (prefs == null) return ThemeMode.system;
    final int? value = prefs.getInt('themeMode');
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere((e) => e.index == value, orElse: () => ThemeMode.system);
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    prefs?.setInt('themeMode', mode.index);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
