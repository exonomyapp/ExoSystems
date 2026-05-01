# ExoTalk UI/UX Design Guidelines

To ensure ExoTalk feels like a premium, state-of-the-art sovereign application, all interface components must adhere to these strict rules.

## 1. Horizontal-First Density
*   **No Redundant Stacking**: If two elements can fit side-by-side on a standard 1000px width, they **must** be in a Row, not a Column.
*   **Labels-to-the-Left**: Section titles (e.g., "Danger Zone", "Network Control") should ideally sit to the left of their content/controls, not on top.
*   **Compact Footprint**: Minimize vertical margins. Use `SizedBox(height: 8)` as the default gap, never 24 or 32 unless it's a major page-level break.
*   **Asymmetric Grids**: Use `flex` tracks (e.g., 5-4-2) for heterogeneous dashboard cards to maximize horizontal width utility.
*   **Intrinsic Anchoring**: Wrap top-level dashboard rows in `IntrinsicHeight` (and use `CrossAxisAlignment.stretch` internally) to ensure all sibling cards share a unified vertical height, preventing "floating" elements.

## 2. Typographic Integrity
*   **Font Ratios**: Heading and Caption sizes must be brought closer together.
    *   *Heading*: ~18px
    *   *Body*: ~14px
    *   *Caption*: ~13px
*   **Alignment**: Subtitles and secondary info should follow the primary title on the **same line** where possible (e.g., using a pipe separator or dimmed color).

## 3. Geometric Matrix & Spacing
*   **Symmetry**: Buttons and interactive elements must have symmetrical padding. `padding: EdgeInsets.symmetric(horizontal: X, vertical: Y)` is the rule.
*   **Alignment**: Component edges (left and right) must align to a strict vertical grid. No "floating" or "indented" boxes unless functionally required.
*   **Surface Consistency**: Use a single, unified border and background logic. No "stacked" shadows or doubled-up borders.

## 4. Visual Language
*   **Accent Color**: Use `ConsciaTheme.accent` (green) for active/functional states.
*   **Error Color**: Use `ConsciaTheme.error` (red) **exclusively** for the Danger Zone and destructive actions.
*   **Toggles**: All switches must be uniformly scaled to 0.7x of default size to maintain high density. They should never be standalone but always labeled horizontally or within a list tile.
*   **Solid Identity**: Avoid all transparency and glassmorphism. Use opaque surfaces (`ConsciaTheme.surface` and `ConsciaTheme.background`) with high-contrast borders (`ConsciaTheme.border`) to create depth and professional clarity.
*   **Window Distinction**: To prevent "flatness" when windows are stacked, use `surfaceElevated` and `borderStrong` for dialogs and modals. This provides necessary visual separation in dark mode without relying on shadows or transparency.
*   **Tristate Theme Modes**: Support Light, Dark, and System modes. All themes must adhere to the "Solid Identity" mandate. Light mode uses a "Paper & Ink" palette (white/light-grey background with high-contrast dark borders).

## 5. Responsive Behavior & Structural Limits
*   **Button Width Stability (The Anchor)**: Buttons must never grow unbounded when their parent container stretches. They should be constrained to a reasonable maximum width (e.g., `maxWidth: 320px`) using `ConstrainedBox` or aligned to their intrinsic size. They may shrink if necessary, but their captions must not wrap to multiple lines. This ensures primary actions look intentional, not bloated.
*   **Fixed Positioning for Critical Information**: While fluid layouts are generally desirable, some elements must resist resizing to maintain legibility. Essential metrics (e.g., Health Dashboard indicators) must remain in their designated fixed position (such as top-right) and should not be allowed to wrap or stack below their label when the container shrinks.
*   **Sacrificing Elasticity for Clarity**: The requirement for critical indicators to remain in their fixed position should actively dictate the minimum width of their container. If a container becomes too narrow, it is better to truncate titles (via `TextOverflow.ellipsis`) or enforce horizontal scrolling rather than breaking the layout matrix. Not everything is better understood by blindly wrapping; sometimes fixing the position against resizing guarantees clear information architecture.
