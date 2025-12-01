# Base image
FROM python:3.11-slim

# Set environment variables
ENV ARCHIPELAGO_HOME=/app

# Install dependencies
RUN apt-get update && \
    apt-get install -y git build-essential wget tk-dev python3-tk && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Clone Archipelago code
WORKDIR $ARCHIPELAGO_HOME
RUN git clone https://github.com/ArchipelagoMW/Archipelago.git .

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

# Create required data files for WebHost
RUN mkdir -p /app/WebHostLib/static/generated && \
    touch /app/data/options.yaml

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose port for WebHost web UI
EXPOSE 80

# Set volumes for persistence and custom content
VOLUME ["/app/custom_worlds", "/app/data", "/app/config"]

# Start the server via entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
