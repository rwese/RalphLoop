#!/bin/bash

# Entrypoint script for OpenCode auth setup
# Creates /root/.local/share/opencode/auth.json if OPENCODE_AUTH is set

set -e

echo "Running OpenCode entrypoint..."

# Check if OPENCODE_AUTH environment variable is set and not empty
if [ -n "$OPENCODE_AUTH" ]; then
    echo "OPENCODE_AUTH is set, creating auth file..."
    
    # Create the directory structure if it doesn't exist
    mkdir -p /root/.local/share/opencode
    
    # Write the auth.json file
    echo "$OPENCODE_AUTH" > /root/.local/share/opencode/auth.json
    
    echo "Auth file created at /root/.local/share/opencode/auth.json"
else
    echo "OPENCODE_AUTH is not set, skipping auth file creation"
fi

# Execute the CMD or default command
exec "$@"
