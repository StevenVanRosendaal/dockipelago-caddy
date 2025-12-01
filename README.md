# Archipelago Docker Container

Docker container for running Archipelago WebHost with:
- Full web UI for generating and hosting multiworld games
- Support for custom game implementations via `.apworld` files
- Persistent configuration and data
- Caddy reverse proxy integration

## Quick Start

### Prerequisites

1. **Create required directories** on your server:
   ```bash
   mkdir -p ~/archipelago/custom_worlds
   ```

2. **A working Caddy container**:

### Deployment via Portainer

1. In Portainer, go to **Stacks** → **Add stack**
2. Select **Repository** as build method
3. Enter repository URL: `https://github.com/StevenVanRosendaal/archipelago-docker`
4. Set repository reference: `main`
5. Under **Environment variables**, add:
   - `USER` = your server username (e.g., `yourusername`)
   - `CADDY_NETWORK` = your Caddy network name (e.g., `caddy`, `caddy_default`, or `proxy`)
6. Click **Deploy the stack**

### Manual Deployment

1. **Clone and run**:
   ```bash
   git clone https://github.com/StevenVanRosendaal/archipelago-docker.git
   cd archipelago-docker
   USER=yourusername CADDY_NETWORK=caddynetworkname docker-compose up -d
   ```

2. **View logs**:
   ```bash
   docker-compose logs -f
   ```

### Caddy Configuration

Add this to your Caddyfile to expose the web UI:

```
your.domain.com {
    reverse_proxy dockipelago-caddy:80
}
```

Then reload Caddy:
```bash
docker exec <caddy-container> caddy reload --config /etc/caddy/Caddyfile
```

## Using the WebHost

Once deployed, access the web interface at `https://your.domain.com` (or your configured domain).

You can:
- Upload YAML configuration files
- Generate multiworld games
- Host games directly from the web UI
- Use the tracker and other tools

## Adding Custom Games

1. Place `.apworld` files in `~/archipelago/custom_worlds/` on your server
2. Restart the container:
   ```bash
   docker-compose restart
   ```
   Or via Portainer: **Containers** → `dockipelago-caddy` → **Restart**

The custom games will be automatically installed and will appear as options in the web UI.

## Connecting to Game Rooms

### How WebHost Assigns Ports

WebHost dynamically assigns a random port (49152-65535) to each game room when it's created. This design supports hosting multiple concurrent rooms.

- **Web UI**: Accessible via Caddy at `https://your.domain.com`
- **Game Rooms**: Each room gets its own port, displayed in the web UI

### Client Connection

When a game room is created, the web UI will show a connection command like:
```
/connect your-server-ip:52341
```

These ports are not exposed by default. You should provide friendly URLs for specific game rooms. You can add Caddy reverse proxy rules for individual ports:

Caddyfile:
```
# Web UI
archipelago.your.domain.com {
    reverse_proxy dockipelago-caddy:80
}

# Example: Proxy a specific game room on port 52341
room1.archipelago.your.domain.com {
    reverse_proxy dockipelago-caddy:52341
}

# Example: Another room on port 53128
room2.archipelago.your.domain.com {
    reverse_proxy dockipelago-caddy:53128
}
```

Then reload Caddy:
```bash
docker exec <caddy-container> caddy reload --config /etc/caddy/Caddyfile
```

**Important**: You must add these entries manually after rooms are created, using the port shown in the WebHost UI.

## Environment Variables

**Required:**
- `USER`: Your server username (files stored at `/home/$USER/archipelago/`)
- `CADDY_NETWORK`: Docker network name used by Caddy (e.g., `caddy`, `caddy_default`, `proxy`)

## Volumes

Files are stored in `/home/$USER/archipelago/` on your server:
- `custom_worlds/`: Place custom `.apworld` files here