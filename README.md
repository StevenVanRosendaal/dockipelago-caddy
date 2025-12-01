# Archipelago Docker Container

Docker container for running Archipelago WebHost with:
- Full web UI for generating and hosting multiworld games
- Support for custom game implementations via `.apworld` files
- Single port enforcement for all game rooms
- Persistent configuration and data
- Caddy reverse proxy integration

## Quick Start

### Prerequisites

1. **Create required directories** on your server:
   ```bash
   mkdir -p ~/archipelago/{custom_worlds,data,config}
   ```

2. **Ensure Caddy network exists**:
   ```bash
   # Check if Caddy network exists
   docker network ls | grep caddy
   
   # If not, create it (adjust name to match your Caddy setup)
   docker network create caddy
   ```

### Deployment via Portainer

1. In Portainer, go to **Stacks** → **Add stack**
2. Select **Repository** as build method
3. Enter repository URL: `https://github.com/StevenVanRosendaal/archipelago-docker`
4. Set repository reference: `main`
5. Under **Environment variables**, add:
   - `USER` = your server username (e.g., `yourusername`)
   - `PUBLIC_HOST` = your server hostname (e.g., `your.domain.com`)
   - `CADDY_NETWORK` = your Caddy network name (e.g., `caddy`, `caddy_default`, or `proxy`)
6. Click **Deploy the stack**

### Manual Deployment

1. **Clone and run**:
   ```bash
   git clone https://github.com/StevenVanRosendaal/archipelago-docker.git
   cd archipelago-docker
   USER=yourusername PUBLIC_HOST=your.domain.com CADDY_NETWORK=caddy docker-compose up -d
   ```

2. **View logs**:
   ```bash
   docker-compose logs -f
   ```

### Caddy Configuration

Add this to your Caddyfile:

```
archipelago.steros.nl {
    reverse_proxy archipelago-server:80
}
```

Then reload Caddy:
```bash
docker exec <caddy-container> caddy reload --config /etc/caddy/Caddyfile
```

## Using the WebHost

Once deployed, access the web interface at `https://archipelago.steros.nl` (or your configured domain).

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
   Or via Portainer: **Containers** → `archipelago-server` → **Restart**

The custom games will be automatically installed and will appear as options in the web UI.

## Configuration

### Port Configuration
Edit `config/host.yaml` to customize server settings. The default enforces single-port mode:

```yaml
host_config:
  host: 0.0.0.0
  port: 38281
  server_password: null
  multiworld_port_range_start: 38281
  multiworld_port_range_end: 38281
```

### Environment Variables

**Required:**
- `USER`: Your server username (files stored at `/home/$USER/archipelago/`)
- `PUBLIC_HOST`: Your server's public hostname (e.g., `archipelago.steros.nl`)
- `CADDY_NETWORK`: Docker network name used by Caddy (e.g., `caddy`, `caddy_default`, `proxy`)

**Optional (defaults shown):**
- `BASE_PORT`: Server port (default: `38281`)
- `PORT_RANGE_START`/`PORT_RANGE_END`: Port range (default: `38281`, enforces single port)

## Volumes

Files are stored in `/home/$USER/archipelago/` on your server:
- `custom_worlds/`: Place custom `.apworld` files here
- `data/`: Persistent server data
- `config/`: Configuration files (host.yaml)

## Building Manually

```bash
docker build -t archipelago-server .
docker run -d -p 38281:38281 \
  -v ~/archipelago/custom_worlds:/app/custom_worlds \
  -v ~/archipelago/data:/app/data \
  -v ~/archipelago/config:/app/config \
  -e PUBLIC_HOST=archipelago.steros.nl \
  archipelago-server
```

## Updating Archipelago

To update to the latest version:

1. Rebuild the container:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```