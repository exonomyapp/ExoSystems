# 17 — Account Manager Stabilization & Menu Interaction Fix

## Summary
This session repaired a structural regression in `account_manager.dart` that had introduced duplicate class definitions, resolved a stale API parameter, and corrected the context menu positioning and sizing behaviour for the unified `_ConsciaMenuButton` component.

## Root Cause
A previous `replace_file_content` call had run over the wrong target range, resulting in two complete definitions of both `_ProfileSection` and `_IdentitySection` inside the same file. Dart compilation failed silently during the session disruption, leaving the file in an inconsistent state.

No git commit or internal snapshot existed that could be restored; the fix was applied directly by auditing the duplicate ranges and surgically removing the older, incomplete copies.

---

## Changes Made

### `exotalk_flutter/lib/widgets/modals/account_manager.dart`

#### 1. Class Deduplication
- Removed the first (stale) definition of `_ProfileSection` (lines 239–291). This version was missing the `onPressed` parameter required by `_ConsciaMenuButton` and would have caused a runtime exception.
- Removed the stub-only `_IdentitySection` class declaration that preceded the full implementation with scroll state and carousel logic.
- The retained implementations are canonical: they include `_ConsciaMenuButton` tactile press feedback (`AnimatedScale` 0.96×), the horizontal carousel with `ListView` + chevron scroll indicators, and "View Proof" / "Remove Link" dropdown actions.

#### 2. Stale Parameter Removal
- Removed `isVerified: profile.isVerified` from the `_ProfileSection` call site — a parameter left over from an earlier version of the constructor that no longer accepts it.

#### 3. Context Menu — Position Below Button
The `_ConsciaMenuButtonState._showMenu` method previously passed a full `Rect` covering the entire button (top-left → bottom-right) as the `RelativeRect` anchor. Flutter's `showMenu` was resolving this ambiguously and placing the menu **on top of** the button.

**Fix:** Anchor the `RelativeRect` to a zero-height rect at the **bottom edge** of the button, so Flutter always resolves the menu below it:

```dart
// Before — ambiguous: Flutter could open menu above OR overlapping the button
Rect.fromPoints(
  button.localToGlobal(Offset.zero, ancestor: overlay),
  button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
)

// After — unambiguous: zero-height rect at button's bottom edge
final Offset buttonBottomLeft = button.localToGlobal(
  button.size.bottomLeft(Offset.zero),
  ancestor: overlay,
);
Rect.fromLTWH(buttonBottomLeft.dx, buttonBottomLeft.dy, button.size.width, 0)
```

#### 4. Context Menu — Compact Item Sizing
Menu item font, icon, and padding were reduced to match the compact 76–80px tile footprint:

| Property | Before | After |
|---|---|---|
| Icon size | `16 × scale` | `14 × scale` |
| Icon→label gap | `12 × scale` | `8 × scale` |
| Font size | `13 × scale` | `11 × scale` |
| Item padding | Flutter default | `h:10 v:6 × scale` |
| Row sizing | unconstrained | `MainAxisSize.min` |

---

## Build Verification

```
✓ Built build/linux/x64/debug/bundle/exotalk_flutter
Exit code: 0
```

A full build and `flutter analyze` reports zero errors. Remaining diagnostics are style-level `info` hints only (prefer_interpolation, withOpacity deprecation) — none affect runtime.

---

## How to Verify

```bash
cd exotalk_flutter
flutter run -d linux
```

1. **Account Manager opens** — no crash, no duplicate widget errors.
2. **Avatar tile** — press and hold; menu appears **below** the avatar circle with compact "Change Photo / Remove Photo" items.
3. **Identity tile** (if verified links exist) — press; menu appears below with "View Proof / Remove Link" items.
4. **Tactile feedback** — every press produces a visible 0.96× scale-down animation before the menu appears.
5. **No overlap** — the menu does not cover the button that triggered it.
