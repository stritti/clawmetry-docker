# Traefik + OpenClaw + ClawMetry

This guide shows how to run **OpenClaw**, **[ClawMetry](https://clawmetry.com/)**, and **Traefik** together using Docker Compose. Traefik acts as a reverse proxy that terminates TLS (via Let's Encrypt) and routes HTTPS requests to the right container — making both services safe to expose on a public VPS or server.

## What you'll build

```
Internet
   │
   ▼
Traefik  (ports 80 / 443)
   ├─ openclaw.example.com  ──▶  OpenClaw gateway  (port 18789)
   └─ clawmetry.example.com ──▶  ClawMetry dashboard (port 8900)
```

Both services share the same host directory (`~/.openclaw`) so that ClawMetry can read the logs, sessions, and metrics produced by the OpenClaw agent.

> **Local development?**
> Skip Traefik and use the simpler [`docker-compose.yml`](docker-compose) together with a standalone `docker run` command for OpenClaw instead.

## Prerequisites

- A Linux server (VPS or dedicated) with a public IP address
- [Docker Engine](https://docs.docker.com/engine/install/) ≥ 24 and Docker Compose v2
- Two (sub)domains that both resolve to your server's IP address, for example:
  - `openclaw.example.com`
  - `clawmetry.example.com`
- Ports **80** and **443** open in your server firewall

## Step 1 — Run the OpenClaw onboarding wizard

ClawMetry reads data written by the OpenClaw gateway. Before using the Traefik compose file you need to configure OpenClaw with its interactive setup wizard.

1. Clone the OpenClaw repository and enter the directory:

   ```bash
   git clone https://github.com/openclaw/openclaw
   cd openclaw
   ```

2. Set the image tag and run the wizard:

   ```bash
   export OPENCLAW_IMAGE="alpine/openclaw:latest"
   ./docker-setup.sh
   ```

   The wizard asks you to:
   - Choose an **AI model** (e.g. OpenAI Codex via OAuth)
   - Select a **messaging channel** (Telegram, WhatsApp, Discord, …)
   - Generate and save a **gateway token**

3. Once setup is complete, stop the wizard-started containers. You will start them again via the Traefik compose file:

   ```bash
   docker compose down
   ```

4. The wizard has written your configuration to `~/.openclaw/`. Confirm it exists:

   ```bash
   ls ~/.openclaw
   ```

> **Troubleshooting:** If the wizard shows no models with `latest`, switch to the `main` tag and rerun:
> ```bash
> export OPENCLAW_IMAGE="alpine/openclaw:main"
> ./docker-setup.sh
> ```

## Step 2 — Create the project directory

Create a dedicated folder for the Traefik setup and change into it:

```bash
mkdir ~/clawmetry-traefik && cd ~/clawmetry-traefik
```

## Step 3 — Create the `.env` file

Copy the example file from this repository and fill in your values:

```bash
cp /path/to/clawmetry-docker/.env.traefik.example .env
```

Or create it manually:

```bash
# Email for Let's Encrypt certificate registration
ACME_EMAIL=your@example.com

# Domains — both must point to this server's public IP
OPENCLAW_DOMAIN=openclaw.example.com
CLAWMETRY_DOMAIN=clawmetry.example.com

# Optional: your display name in the ClawMetry Flow tab
OPENCLAW_USER=
```

> **Tip:** Add `.env` to your `.gitignore` to avoid accidentally committing it.

## Step 4 — Create the `docker-compose.yml`

Create a `docker-compose.yml` in your project directory with the following content.
The file is also available as [`docker-compose.traefik.yml`](https://github.com/stritti/clawmetry-docker/blob/main/docker-compose.traefik.yml) in this repository — copy and rename it.

```yaml
services:

  # ─── Traefik reverse proxy ──────────────────────────────────────────────
  traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      # Redirect HTTP → HTTPS
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      # Let's Encrypt TLS certificates
      - "--certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certs:/letsencrypt
    restart: unless-stopped
    networks:
      - proxy

  # ─── OpenClaw gateway ───────────────────────────────────────────────────
  openclaw-gateway:
    image: alpine/openclaw:latest
    user: "1000:1000"
    volumes:
      - ~/.openclaw:/home/node/.openclaw
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.openclaw.rule=Host(`${OPENCLAW_DOMAIN}`)"
      - "traefik.http.routers.openclaw.entrypoints=websecure"
      - "traefik.http.routers.openclaw.tls.certresolver=letsencrypt"
      - "traefik.http.services.openclaw.loadbalancer.server.port=18789"
    restart: unless-stopped
    networks:
      - proxy
      - internal
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1G

  # ─── ClawMetry dashboard ────────────────────────────────────────────────
  clawmetry:
    image: stritti/clawmetry:latest
    volumes:
      - ~/.openclaw:/home/clawmetry/.openclaw:ro
    environment:
      OPENCLAW_DATA_DIR: /home/clawmetry/.openclaw
      OPENCLAW_USER: "${OPENCLAW_USER:-}"
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      - "traefik.http.routers.clawmetry.rule=Host(`${CLAWMETRY_DOMAIN}`)"
      - "traefik.http.routers.clawmetry.entrypoints=websecure"
      - "traefik.http.routers.clawmetry.tls.certresolver=letsencrypt"
      - "traefik.http.services.clawmetry.loadbalancer.server.port=8900"
    restart: unless-stopped
    networks:
      - proxy
      - internal

volumes:
  traefik-certs:

networks:
  proxy:
  internal:
    internal: true
```

## Step 5 — Fix file permissions

Both containers run as user `1000`. If your `~/.openclaw` directory was created by a different user, fix the ownership before starting the stack:

```bash
sudo chown -R 1000:1000 ~/.openclaw
```

## Step 6 — Start the stack

```bash
docker compose up -d
```

Traefik automatically requests TLS certificates from Let's Encrypt when the first request arrives. This can take up to a minute. Check that all three containers are running:

```bash
docker compose ps
```

Expected output:

```
NAME                  IMAGE                       STATUS
clawmetry-traefik-traefik-1          traefik:v3.0                Up
clawmetry-traefik-openclaw-gateway-1 alpine/openclaw:latest      Up
clawmetry-traefik-clawmetry-1        stritti/clawmetry:latest    Up
```

## Step 7 — Connect OpenClaw to the gateway

Fetch the Control UI URL and paste your gateway token into **Settings → Token**:

```bash
docker compose exec openclaw-gateway openclaw-cli dashboard --no-open
```

Open the printed URL in your browser and enter the gateway token (the value you noted during the wizard in Step 1, or found in `~/.openclaw/.env`).

## Step 8 — Open the ClawMetry dashboard

Navigate to `https://clawmetry.example.com` (replace with your `CLAWMETRY_DOMAIN`).
The [ClawMetry](https://clawmetry.com/) dashboard shows live metrics, session recordings, and logs streamed from the shared `~/.openclaw` directory.

## Security considerations

| Topic | Recommendation |
|---|---|
| Non-root containers | Both ClawMetry and OpenClaw run as user `1000` — never add `privileged: true`. |
| Read-only volume | ClawMetry mounts `~/.openclaw` with `:ro` — it cannot modify agent data. |
| Internal network | The `internal` network has no direct internet routing — containers communicate with each other but external traffic must pass through Traefik. |
| TLS | Traefik provisions certificates automatically — never expose ports `8900` or `18789` directly on a public server. |
| Resource limits | The `deploy.resources.limits` block prevents a runaway agent from consuming all available CPU and memory. |
| Traefik dashboard | The Traefik API/dashboard is disabled by default in this configuration. Enable it only temporarily and protect it with basic auth if needed. |

## Useful commands

```bash
# View logs for all services
docker compose logs -f

# View ClawMetry logs only
docker compose logs -f clawmetry

# Restart a single service
docker compose restart clawmetry

# Stop the stack (data is preserved)
docker compose down

# Stop the stack and remove all volumes (destructive!)
docker compose down -v
```

## Next steps

- See the [Configuration reference](/guide/configuration) for all supported environment variables.
- See [Docker Compose](/guide/docker-compose) for a simpler single-service setup without Traefik.
