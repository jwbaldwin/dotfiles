#!/usr/bin/env bash
# bootstrap.sh
# Ensures core dependencies (like Homebrew, Ansible) are installed.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
# set -u # Be careful with this, might break things if scripts aren't perfectly written
# Pipefail: return value of a pipeline is the status of the last command to exit with non-zero status
set -o pipefail

# Function to print messages
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

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

install_homebrew() {
  if ! command_exists brew; then
    info "Homebrew not found. Installing Homebrew..."
    # Run the official Homebrew installation script
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # On macOS ARM, brew is in /opt/homebrew/bin
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    # On macOS Intel, brew is in /usr/local/bin
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if ! command_exists brew; then
       fail "Homebrew installation failed."
    fi
     success "Homebrew installed successfully."
  else
    success "Homebrew is already installed."
  fi
}

install_ansible() {
  if ! command_exists ansible; then
    info "Ansible not found. Installing Ansible via Homebrew..."
    brew install ansible || fail "Failed to install Ansible."
    success "Ansible installed successfully."
  else
    success "Ansible is already installed."
  fi
}

# --- Main Script ---
info "Starting to bootstrap new workstation..."

os_type=$(uname)

# Check for Xcode Command Line Tools (needed for Homebrew)
if ! xcode-select -p > /dev/null 2>&1; then
    info "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    # Note: This requires user interaction. Script might pause here.
    info "Please follow the prompts to install Xcode Command Line Tools."
    # Simple loop to wait until installation is likely done (basic check)
    while ! xcode-select -p > /dev/null 2>&1; do
        sleep 5
    done
    success "Xcode Command Line Tools installed."
else
    success "Xcode Command Line Tools already installed."
fi
install_homebrew
install_ansible

echo ""
success "Bootstrap complete. Ansible should now be installed."
info "You can now run the main setup using the './setup.sh' script."
echo ""
