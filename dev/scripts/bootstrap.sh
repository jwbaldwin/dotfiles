#!/usr/bin/env bash
# bootstrap.sh
# Sets up a new macOS machine with Homebrew, packages, Rust, and mise-managed languages.

set -e
set -o pipefail

# Script directory (for locating Brewfile)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Helper Functions ---

info() {
	printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
}

success() {
	printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
}

fail() {
	printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
	echo ''
	exit 1
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# --- Installation Functions ---

install_xcode_cli_tools() {
	if xcode-select -p >/dev/null 2>&1; then
		success "Xcode Command Line Tools already installed."
		return
	fi

	info "Xcode Command Line Tools not found. Installing..."
	xcode-select --install

	# Wait for installation to complete
	info "Please follow the prompts to install Xcode Command Line Tools."
	while ! xcode-select -p >/dev/null 2>&1; do
		sleep 5
	done
	success "Xcode Command Line Tools installed."
}

install_homebrew() {
	if command_exists brew; then
		success "Homebrew is already installed."
		return
	fi

	info "Homebrew not found. Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Configure Homebrew in PATH for this session
	if [[ -x "/opt/homebrew/bin/brew" ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x "/usr/local/bin/brew" ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi

	if ! command_exists brew; then
		fail "Homebrew installation failed."
	fi
	success "Homebrew installed successfully."
}

install_packages() {
	local brewfile="$SCRIPT_DIR/packages/Brewfile"

	if [[ ! -f "$brewfile" ]]; then
		fail "Brewfile not found at $brewfile"
	fi

	info "Installing packages from Brewfile..."
	brew bundle --file="$brewfile"
	success "Packages installed successfully."
}

install_rust() {
	if command_exists rustc; then
		success "Rust is already installed."
		return
	fi

	info "Installing Rust via rustup..."
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable

	# Source cargo env for this session
	if [[ -f "$HOME/.cargo/env" ]]; then
		source "$HOME/.cargo/env"
	fi

	if ! command_exists rustc; then
		fail "Rust installation failed."
	fi
	success "Rust installed successfully."
}

install_mise_languages() {
	if ! command_exists mise; then
		fail "mise not found. It should have been installed via Brewfile."
	fi

	info "Installing languages via mise..."

	info "  Installing Node.js (LTS)..."
	mise use -g node@lts

	info "  Installing Python..."
	mise use -g python@latest

	info "  Installing Go..."
	mise use -g go@latest

	info "  Installing Erlang..."
	mise use -g erlang@latest

	info "  Installing Elixir..."
	mise use -g elixir@latest

	success "Languages installed via mise."
}

# --- Main ---

main() {
	info "Starting bootstrap for new workstation..."
	echo ""

	install_xcode_cli_tools
	install_homebrew
	install_packages
	install_rust
	install_mise_languages

	echo ""
	success "Bootstrap complete!"
	info "You may need to restart your shell for all changes to take effect."
}

main
