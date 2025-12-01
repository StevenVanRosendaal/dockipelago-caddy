# Base image
FROM python:3.11-slim

# Set environment variables
ENV ARCHIPELAGO_HOME=/app
ENV PUBLIC_HOST=archipelago.steros.nl
ENV BASE_PORT=38281
ENV PORT_RANGE_START=38281
ENV PORT_RANGE_END=38281

# Install dependencies
RUN apt-get update && \
    apt-get install -y git build-essential wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Copy / clone Archipelago code
WORKDIR $ARCHIPELAGO_HOME
RUN git clone https://github.com/ArchipelagoMW/Archipelago.git . && \
    ls -la /app/ && \
    echo "Verifying MultiServer.py exists..." && \
    test -f /app/MultiServer.py || (echo "ERROR: MultiServer.py not found!" && find /app -name "*.py" | head -10 && exit 1)

# Install Python requirements
# Archipelago uses ModuleUpdate.py to install dependencies
RUN echo "Installing Archipelago dependencies..." && \
    python ModuleUpdate.py --yes --force

# Install WebHost specific requirements
RUN pip install --no-cache-dir -r WebHostLib/requirements.txt

# Patch ModuleUpdate.py to auto-confirm in non-interactive environments
COPY patch_moduleupdate.py /tmp/patch_moduleupdate.py
RUN python3 /tmp/patch_moduleupdate.py && rm /tmp/patch_moduleupdate.py

# Create directories for custom games and data persistence
RUN mkdir -p /app/custom_worlds /app/data /app/config

# Create host.yaml configuration file with single port enforcement
RUN echo "host_config:" > /app/config/host.yaml && \
    echo "  host: 0.0.0.0" >> /app/config/host.yaml && \
    echo "  port: 38281" >> /app/config/host.yaml && \
    echo "  server_password: null" >> /app/config/host.yaml && \
    echo "  multiworld_port_range_start: 38281" >> /app/config/host.yaml && \
    echo "  multiworld_port_range_end: 38281" >> /app/config/host.yaml

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose ports for WebHost and game servers
EXPOSE 80 38281

# Set volumes for persistence and custom content
VOLUME ["/app/custom_worlds", "/app/data", "/app/config"]

# Start the server via entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
