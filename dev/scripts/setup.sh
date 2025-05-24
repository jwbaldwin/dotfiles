#!/usr/bin/env bash
# Checks for Ansible (should be installed by ./bootstrap.sh already) and executes the main Ansible playbook for setup.

# Exit immediately if a command exits with a non-zero status.
set -e
set -o pipefail

# Function to print messages
info() {
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
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

# --- Main Script ---

info "Checking prerequisites for running Ansible setup..."

# 1. Check if Ansible is installed
if ! command_exists ansible-playbook; then
  fail "Ansible command ('ansible-playbook') not found. Please run './bootstrap.sh' first."
fi

info "Ansible found. Proceeding with setup..."

# 2. Determine the script's directory to reliably find the 'ansible' subdir
#    This works even if the script is called from a different directory.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
ANSIBLE_DIR="$SCRIPT_DIR/ansible"

if [ ! -d "$ANSIBLE_DIR" ]; then
  fail "Ansible directory not found at '$ANSIBLE_DIR'. Ensure it exists relative to this script."
fi

if [ ! -f "$ANSIBLE_DIR/playbook.yml" ]; then
   fail "Ansible playbook not found at '$ANSIBLE_DIR/playbook.yml'."
fi

# 3. Navigate to the Ansible directory and run the playbook
info "Changing directory to $ANSIBLE_DIR"
cd "$ANSIBLE_DIR"

info "Running Ansible playbook: ansible-playbook playbook.yml $*"
echo "----------------------------------------------------------------------"

# Execute Ansible playbook, passing any arguments received by this script
# For example, you could run ./run-ansible.sh -K (to ask for sudo password)
# or ./run-ansible.sh --tags "cli" (to run specific tagged tasks)
ansible-playbook playbook.yml "$@"

echo "----------------------------------------------------------------------"
info "Ansible playbook execution finished."

# Optional: Change back to the original directory
# cd - > /dev/null

echo ""
info "Setup script completed."
