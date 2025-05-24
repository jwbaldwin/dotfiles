#!/bin/bash
# notify_command.sh - Script to run commands and notify on completion for macOS

# Check if a command was provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <command>"
  echo "Example: $0 'mix do deps.get, compile'"
  exit 1
fi

# Get the command from arguments
COMMAND="$*"

# Run command
echo "Running $COMMAND..."
eval "$COMMAND"
EXIT_CODE=$?

# Function to display notification on macOS
notify_macos() {
    local title="$1"
    local message="$2"
    local sound="$3"
    
    osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
}

if [ $EXIT_CODE -eq 0 ]; then
    # Success case
    echo "✅ Command succeeded: '$COMMAND'"
    
    # Play success sound
    afplay /System/Library/Sounds/Hero.aiff
    notify_macos "Command complete" "'$COMMAND' succeeded! 🎉" "Hero"
else
    # Failure case
    echo "❌ Command failed: '$COMMAND'"
    
    # Play failure sound
    afplay /System/Library/Sounds/Ping.aiff
    notify_macos "Command failed" "'$COMMAND' failed ⚠️" "Ping"
fi

exit $EXIT_CODE
