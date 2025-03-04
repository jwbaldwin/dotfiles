#!/bin/bash
# mix_compile_notify.sh - Script to run mix commands and notify on completion for macOS

# Run mix commands
echo "Running mix do deps.get, compile..."
mix do deps.get, compile
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
    echo "✅ Mix compilation succeeded!"
    
    # Play success sound
    afplay /System/Library/Sounds/Hero.aiff
    notify_macos "Elixir" "Compilation succeeded! 🎉" "Hero"
else
    # Failure case
    echo "❌ Mix compilation failed!"
    
    # Play failure sound
    afplay /System/Library/Sounds/Ping.aiff
    notify_macos "Elixir" "Compilation failed" ⚠️"Ping"
fi

exit $EXIT_CODE
