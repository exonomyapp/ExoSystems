# Specification 26: Copy Fail Remediation (CVE-2026-31431)

## 1. Overview
This document details the identification and remediation of **CVE-2026-31431**, colloquially known as **"Copy Fail"**, across the Exosystem infrastructure (Exocracy and Exonomy).

"Copy Fail" is a high-severity local privilege escalation (LPE) vulnerability in the Linux kernel crypto subsystem (`algif_aead`). It allows a 4-byte write into the page cache, enabling root access by modifying setuid binaries in memory.

## 2. Infrastructure Audit (May 02, 2026)

| Node | Hostname | Kernel Version (Original) | Build Date | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Dev Node** | `exocracy` | `6.17.0-22-generic` | Mar 26, 2026 | 🔴 Vulnerable |
| **Edge Node** | `exonomy` | `6.17.0-22-generic` | Mar 26, 2026 | 🔴 Vulnerable |

### Identification
The vulnerability affects kernels built prior to late April 2026. The `algif_aead` module was found to be present on both systems.

## 3. Remediation Strategy
The remediation follows the standard maintenance protocol:
1.  **Immediate Block**: Blacklist the `algif_aead` module to prevent exploitation without a reboot.
2.  **Kernel Upgrade**: Install the patched `6.17.0-23` series kernel from the Ubuntu security repositories.
3.  **Active Cleanup**: Drop caches to clear any potential page cache corruption.
4.  **Verification**: Reboot nodes to finalize protection.

## 4. Execution Log

### Phase 1: Exocracy (Local)
- [x] Blacklist `algif_aead`
- [x] Install `linux-image-6.17.0-23-generic`
- [x] Verify installation (v6.17.0-23 in /boot)

### Phase 2: Exonomy (Remote Tunnel)
- [x] Remote Blacklist `algif_aead`
- [x] Remote Install `linux-image-6.17.0-23-generic`
- [x] Verify remote installation (v6.17.0-23 in /boot)

## 5. Post-Remediation Status
**PATCHED (Awaiting Reboot)**.
The `algif_aead` module is blacklisted, preventing new exploitation. The page cache has been purged (`vm.drop_caches=3`) to clear potential corruption. The system will be fully protected upon the next boot into kernel `6.17.0-23`.
