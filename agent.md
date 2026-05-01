# Antigravity Agent Instructions

## 1. Core Directives
- **Systematic Architecture**: Always prefer systemic, theme-aligned solutions over ad-hoc "prototyping" patches.
- **Grid-First Architecture**: Use `flutter_layout_grid` for all complex, multi-dimensional UI components (Dashboards, Metrics, Settings). Align with CSS Grid principles (Rachel Andrew/Jen Simmons) to ensure deterministic scaling.
- **Responsive Design**: Never use hardcoded fixed sizing for UI components unless it is derived from a parent constraint (e.g., LayoutBuilder).
- **Theme Integrity**: All UI dimensions, colors, and typography must be derived from `ConsciaTheme` tokens.
- **Sliver Standard**: Prefer `CustomScrollView` and Sliver-based layouts for scrollable views to ensure total horizontal expansion and viewport alignment.
- **Strict Adherence**: Never deviate from explicit instructions. Do not add "imaginary" steps, tasks, or features. No unsolicited aesthetics or "premium" visuals unless explicitly requested.
- **Pre-Action Verification**: Always verify the existence of files, the state of the codebase, and the accuracy of all assumptions against the actual repository before taking any action. Never act on an assumption that a file or resource is missing; verify it first.

## 2. Regression & "Again" Protocol (Groundhog Day Prevention)
- **Keyword Trigger**: If the user uses the word **"again"** or implies that a problem is repeating, you MUST treat this as a high-priority architectural regression.
- **Mandatory Research**: Before proposing a new fix for a repeating issue, you MUST:
    1.  Search the `walkthrough.md` files for previous mentions of the problem.
    2.  Review past `implementation_plan.md` artifacts to understand how it was "fixed" before.
    3.  Analyze why the previous solution failed to persist or why it was reverted.
- **Systemic Resolution**: Do not re-apply the same patch. Investigate the root cause (e.g., layout collisions, missing persistence, incorrect state management) and implement a systemic solution that prevents the issue from ever occurring "again".

## 3. "Test Before Deliver" Protocol (Mandatory Verification)
- **Mandatory Build Check**: Always run `flutter build linux --debug` (or relevant platform build) before declaring a task complete. No "stealth" syntax errors.
- **Keystroke-Driven Testing**: For all UI modifications, you MUST verify functionality by assigning and triggering keyboard shortcuts.
- **Visual Auditing**: While `xdotool` mouse actions are prohibited, `scrot` screenshots are REQUIRED following a successful keystroke to provide visual evidence for documentation and tutorials.
- **Programmatic Focus**: Functional verification must be driven by [Spec 19](docs/spec/19_verification_telemetry_api.md). Visual inspection is for layout sanity and asset generation, not for the primary pass/fail criteria.

## 4. Communication Style
- Be concise and technical.
- **Clarity Over Flair**: Prioritize technical accuracy and process transparency over descriptive language.
- Use Github-style markdown and clear diffs.
- Prioritize artifacts for complex plans and walkthroughs.

## 5. Housekeeping Protocol
- **Session Wrap-Up**: At the conclusion of a major structural or feature session, you MUST offer to stage and `git commit` the codebase. This locks in a clean baseline and prevents sprawling, unmanageable diffs.
- **Documentation Hygiene**: Documentation must only state *what is*. Do not use comments or readmes as changelogs or historical archives. Walkthroughs serve as the historical record, not source code or specs.

## 6. Desktop Control & Remote Orchestration
You have direct control over the local Ubuntu desktop (`DISPLAY=:1`) and remote control capability for the Exonomy system via SSH + X11.

### 6.1 Remote Control Protocol (Exocracy to Exonomy)
For all remote desktop interactions (Exonomy), follow the **Keystroke-Driven, Visual-Verified (KDVV)** protocol:

1.  **Mandatory X11 Mode**: Ensure the target machine is in X11 mode (`WaylandEnable=false` in `/etc/gdm3/custom.conf`).
2.  **Readability Standard**: Use `xterm` for visible interaction. Always launch with `-fa 'Monospace' -fs 14` for high-fidelity recording and user readability.
3.  **Deterministic Window Naming**: Assign a unique, descriptive title to every terminal upon launch:
    *   `xterm -T 'ADMIN_CONSOLE'`
    *   `xterm -T 'CONSCIA_LOGS'`
    *   `xterm -T 'EXE_ORCHESTRATOR'`
4.  **Targeting by Title/ID**: Always use explicit window activation before typing:
    *   `WID=$(xdotool search --name 'ADMIN_CONSOLE' | head -n 1); xdotool windowactivate --sync $WID`
5.  **Scrolling History Enforcement**: Force a scrolling log for all commands to allow historical auditing. Pipe interactive commands to `cat`:
    *   `sudo snap remove code 2>&1 | cat`
6.  **Visual Synchronization**: Capture desktop screenshots (`scrot`) after each major task phase to synchronize the user's visual state with your internal state.

### 6.2 Local Desktop Capability
- **Window Discovery**: `DISPLAY=:1 wmctrl -l` — lists all open windows with IDs and titles.
- **Window Manipulation**: `DISPLAY=:1 xdotool windowactivate <id>`, `xdotool windowsize <id> <w> <h>`, `xdotool windowclose <id>` — activate, resize, and close windows.
- **Keystroke Injection**: `DISPLAY=:1 xdotool key <sequence>` — Use this to trigger UI events bound to shortcuts.
- **Verification Hierarchy**: 1. Programmatic state check (logs/API) → 2. Millisecond timing → 3. Visual screenshot/video audit (Split-screen for federation).

## 7. Improvement & Deferred Action Protocol
- **Capture, Don't Diverge**: If you identify potential UI/UX or architectural improvements while working on a task, do NOT implement them immediately unless they are critical to the current goal. 
- **Standardized Logging**: Record all such findings in a central `improvement_notes.md` file within the conversation artifacts.
- **Reporting**: Bring these suggestions to the user's attention only after the primary task is completed and verified. This prevents scope creep while ensuring technical excellence is captured.

## 8. Safe Deletion Protocol
- **Prohibition of `rm` and `rm -rf`**: You are strictly FORBIDDEN from using `rm` or `rm -rf` to delete user files or directories.
- **Mandatory Trash Usage**: All file and directory deletions must utilize the Ubuntu trash mechanism to allow for user recovery. You must use `gio trash <path>` or `trash-put <path>` instead of standard coreutils deletion commands.
