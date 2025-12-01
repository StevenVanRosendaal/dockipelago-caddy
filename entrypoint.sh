#!/bin/bash
set -e

echo "Starting Archipelago WebHost..."

# Archipelago WebHost for web UI
WEBHOST_SCRIPT="/app/WebHost.py"

if [ ! -f "$WEBHOST_SCRIPT" ]; then
    echo "ERROR: Cannot find WebHost.py at $WEBHOST_SCRIPT"
    echo "Contents of /app:"
    ls -la /app/ | head -20
    exit 1
fi

echo "Found WebHost at: $WEBHOST_SCRIPT"

# Skip ModuleUpdate at runtime since dependencies are installed during build
export SKIP_MODULEUPDATE=1

# Create required data files if they don't exist (volume might be empty)
if [ ! -f "/app/data/options.yaml" ]; then
    echo "Creating missing options.yaml..."
    touch /app/data/options.yaml
fi

# Create host.yaml if it doesn't exist
if [ ! -f "/root/.local/state/Archipelago/host.yaml" ]; then
    mkdir -p /root/.local/state/Archipelago
    cat > /root/.local/state/Archipelago/host.yaml << EOF
lttp_options:
  rom_file: null
server_options:
  port: ${BASE_PORT}
  host: 0.0.0.0
  server_password: null
multiworld_options:
  port_range_start: ${PORT_RANGE_START}
  port_range_end: ${PORT_RANGE_END}
EOF
    echo "Created host.yaml with single port configuration (${BASE_PORT})"
else
    echo "Using existing host.yaml"
fi

# Copy custom worlds from mounted volume to worlds directory
if [ -d "/app/custom_worlds" ] && [ "$(ls -A /app/custom_worlds 2>/dev/null)" ]; then
    echo "Installing custom APWorld files..."
    WORLDS_DIR=$(find /app -type d -name "worlds" | head -1)
    if [ -n "$WORLDS_DIR" ]; then
        for apworld in /app/custom_worlds/*.apworld; do
            if [ -f "$apworld" ]; then
                echo "  - Installing $(basename $apworld) to $WORLDS_DIR"
                cp "$apworld" "$WORLDS_DIR/" 2>/dev/null || true
            fi
        done
    fi
fi

# Start the Archipelago WebHost
echo "=========================================="
echo "Starting Archipelago WebHost"
echo "Web Interface: http://${PUBLIC_HOST}"
echo "Custom worlds directory: /app/custom_worlds"
echo "=========================================="

exec python "$WEBHOST_SCRIPT" --host 0.0.0.0 --port 80
