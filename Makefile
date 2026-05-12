# =============================================================================
# EXOSYSTEM MONOREPO ORCHESTRATOR
# =============================================================================
# 🧠 EDUCATIONAL CONTEXT: The Makefile
# This is the singular entry point for building the entire Triad. 
# It handles the context-switching between Rust (Conscia/Installer)
# and Flutter (ConSoul), ensuring that all artifacts are built with
# consistent flags and collected into a standardized `dist/` area.
#
# Usage:
#   make build-all    # Compiles everything
#   make package      # Stages files for .deb creation
#   make clean        # Wipes all build artifacts

.PHONY: build-conscia build-consoul build-installer build-all package clean help

help:
	@echo "Exosystem Build Orchestrator"
	@echo "----------------------------"
	@echo "build-all       - Build Conscia, ConSoul, and Installer"
	@echo "package         - Stage all binaries in dist/ for distribution"
	@echo "clean           - Remove all build artifacts"

build-conscia:
	@echo "Building Conscia Daemon..."
	cd conscia && cargo build --release

build-consoul:
	@echo "Building ConSoul Desktop UI..."
	cd conscia_flutter && flutter build linux --release

build-installer:
	@echo "Building FHS Installer..."
	cd exo-installer && cargo build --release

build-all: build-conscia build-consoul build-installer
	@echo "All Triad components built successfully."

package: build-all
	@echo "Staging artifacts for FHS distribution..."
	mkdir -p dist/opt/exo/conscia
	mkdir -p dist/opt/exo/ui
	mkdir -p dist/usr/bin
	
	# Core Daemon
	cp target/release/conscia dist/opt/exo/conscia/
	
	# Desktop UI (Flutter bundle)
	cp -r conscia_flutter/build/linux/x64/release/bundle/* dist/opt/exo/ui/
	
	# Installer (Standalone binary)
	cp target/release/exo-installer dist/usr/bin/
	
	@echo "Staging complete. Artifacts available in dist/"

clean:
	cargo clean
	cd conscia_flutter && flutter clean
	rm -rf dist/
