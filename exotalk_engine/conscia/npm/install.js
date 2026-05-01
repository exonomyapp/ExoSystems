// =============================================================================
// install.js — Conscia NPM Post-Install Binary Fetcher
// =============================================================================
// This script is the "last-mile delivery" mechanism for the @exotalk/conscia
// NPM package. When a developer runs `npm install -g @exotalk/conscia`, Node
// executes this script as a postinstall hook.
//
// Instead of bundling a platform-specific binary inside the NPM package
// (which would require a separate package per OS/arch), we:
//   1. Detect the host OS and CPU architecture at install time.
//   2. Construct the correct GitHub Release asset URL for that platform.
//   3. Download the compressed binary, extract it, and place it in `./bin/`.
//
// This is the same pattern used by tools like `esbuild`, `turbo`, and `bun`.
// =============================================================================

'use strict';

const fs = require('fs');
const path = require('path');
const https = require('https');
const { execSync } = require('child_process');

// ---------------------------------------------------------------------------
// CONFIGURATION
// ---------------------------------------------------------------------------
// These constants must be updated every time a new version is tagged and
// released on GitHub. The CI pipeline should automate this bump.
// ---------------------------------------------------------------------------

const REPO = 'exonomy/exotalk';
const VERSION = '0.7.7'; // Pin to current release; CI will bump this via sed

// Maps Node.js `process.platform` + `process.arch` pairs to the asset name
// suffix used in the GitHub Release. Extend this table when adding new targets.
const PLATFORM_MAP = {
  'linux-x64':   'conscia-linux-x86_64.tar.gz',
  'linux-arm64': 'conscia-linux-aarch64.tar.gz',
  'darwin-x64':  'conscia-macos-x86_64.tar.gz',
  'darwin-arm64':'conscia-macos-aarch64.tar.gz',
  'win32-x64':   'conscia-windows-x86_64.zip',
};

// ---------------------------------------------------------------------------
// UTILITY: Simple HTTPS GET that follows redirects
// GitHub Releases return a 302 redirect to S3; we must follow it manually
// because Node's built-in `https` module does not auto-redirect.
// ---------------------------------------------------------------------------
function download(url, destPath) {
  return new Promise((resolve, reject) => {
    function get(url) {
      https.get(url, { headers: { 'User-Agent': 'conscia-npm-installer' } }, (res) => {
        // GitHub serves a 302 redirect to the actual S3 CDN URL.
        if (res.statusCode === 301 || res.statusCode === 302) {
          return get(res.headers.location);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`HTTP ${res.statusCode} downloading ${url}`));
        }
        const file = fs.createWriteStream(destPath);
        res.pipe(file);
        file.on('finish', () => { file.close(); resolve(); });
        file.on('error', reject);
      }).on('error', reject);
    }
    get(url);
  });
}

// ---------------------------------------------------------------------------
// MAIN INSTALLER
// ---------------------------------------------------------------------------
async function install() {
  const platform = process.platform; // e.g. 'linux', 'darwin', 'win32'
  const arch     = process.arch;     // e.g. 'x64', 'arm64'
  const key      = `${platform}-${arch}`;
  const asset    = PLATFORM_MAP[key];

  console.log(`\n--- 🛰️  Conscia Node Delivery (${key}) ---`);

  if (!asset) {
    // Fail gracefully: unsupported platforms can still build from source.
    console.warn(`\n⚠️  No pre-built binary available for ${key}.`);
    console.warn(`   Build from source: https://github.com/${REPO}#building\n`);
    process.exit(0); // Exit 0 so `npm install` does not fail entirely.
  }

  const url     = `https://github.com/${REPO}/releases/download/v${VERSION}/${asset}`;
  const binDir  = path.join(__dirname, 'bin');
  const tmpFile = path.join(binDir, asset);

  // Ensure the bin/ directory exists before writing into it.
  fs.mkdirSync(binDir, { recursive: true });

  console.log(`   Fetching: ${url}`);

  try {
    await download(url, tmpFile);
    console.log(`   Download complete. Extracting...`);

    if (asset.endsWith('.tar.gz')) {
      // `tar` is available on macOS and all modern Linux distributions.
      execSync(`tar -xzf "${tmpFile}" -C "${binDir}"`, { stdio: 'inherit' });
    } else if (asset.endsWith('.zip')) {
      // `unzip` is standard on Windows via PowerShell.
      execSync(`powershell -command "Expand-Archive -Path '${tmpFile}' -DestinationPath '${binDir}'"`, { stdio: 'inherit' });
    }

    // Remove the compressed archive; only the binary is needed at runtime.
    fs.unlinkSync(tmpFile);
    console.log(`   ✅ Conscia v${VERSION} installed to ${binDir}\n`);

  } catch (err) {
    // Provide a clear, actionable error rather than a raw stack trace.
    console.error(`\n❌ Installation failed: ${err.message}`);
    console.error(`   Manual install: cargo install conscia --version ${VERSION}\n`);
    process.exit(1);
  }
}

install();
