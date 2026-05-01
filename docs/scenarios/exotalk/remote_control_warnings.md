# Warning: Remote Control Anti-Patterns

This document serves as a historical warning against specific techniques that failed during the initial attempts to educationally control the Exonomy desktop from the Exocracy machine. **Do not repeat these approaches.**

## 1. The Wayland Security Barrier
- **FAILED TECHNIQUE**: Attempting to use `xdotool` or `scrot` on a default Ubuntu 24.04 (Wayland-based) installation.
- **WHY IT FAILED**: Wayland’s security model explicitly blocks "silent" screen peeking and remote input injection for security. Attempts to bypass this via D-Bus portals (`xdg-desktop-portal`) trigger mandatory interactive user prompts ("Allow Screen Sharing?"), which break automated, deterministic control.
- **LESSON**: Never attempt remote automation on Wayland. **Always switch to X11** by setting `WaylandEnable=false` in `/etc/gdm3/custom.conf`.

## 2. Background "Silent" Commands
- **FAILED TECHNIQUE**: Running cleanup or diagnostic tasks purely via SSH in the background without visual feedback on the desktop.
- **WHY IT FAILED**: The user (MC/Director) requires visual transparency to audit the process and provide education. "Silent" commands leave the screen motionless, leading to confusion and loss of situational awareness.
- **LESSON**: All administrative actions must be mirrored in a visible terminal on the target desktop (KDVV Protocol).

## 3. Ambiguous Window Identification
- **FAILED TECHNIQUE**: Sending commands to windows using generic searches (e.g., `xdotool search --class gnome-terminal`) when multiple terminals are open.
- **WHY IT FAILED**: Multiple terminals often share the same class or initial title. Commands frequently landed in the "wrong" window (e.g., typing into a log stream instead of an admin console), leading to syntax corruption and failed execution.
- **LESSON**: Always assign a **truly unique title** to each terminal at creation and target it specifically.

## 4. Interactive Command Clutter
- **FAILED TECHNIQUE**: Running commands with interactive progress bars (like `snap remove`) directly in the terminal.
- **WHY IT FAILED**: Progress bars often overwrite the same line repeatedly, hiding the historical command log. This makes it impossible for the user to scroll back and audit exactly what was done.
- **LESSON**: Force "Streaming" or "Scrolling" mode by piping output to `cat` (e.g., `command 2>&1 | cat`) to ensure every line is preserved in the terminal history.

## 5. Poor UI Readability
- **FAILED TECHNIQUE**: Using default `xterm` settings (small font, standard colors).
- **WHY IT FAILED**: Small fonts are unreadable in remote sessions and video recordings, making the "Educational Control" aspect ineffective.
- **LESSON**: Always configure terminals for high readability (`-fa 'Monospace' -fs 14`) for the benefit of the user and future viewers.

## 6. Process "Ghosting"
- **FAILED TECHNIQUE**: Backgrounding long-running processes (like `conscia &`) in a way that allows them to auto-restart or hang in the foreground shell.
- **WHY IT FAILED**: If a process restarts or clutters the admin terminal, it scrolls away the history the user is trying to read.
- **LESSON**: Use dedicated terminals for long-running logs and separate terminals for administrative commands.
