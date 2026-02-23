# Traefik + OpenClaw + ClawMetry (Internal Setup)

This guide shows how to run **OpenClaw**, **[ClawMetry](https://clawmetry.com/)**, and **Traefik** together on a local network (home lab, LAN) using Docker Compose. Traefik acts as a reverse proxy on port 80 and protects both services with **HTTP Basic Auth** — so no one without the password can access them.

> **This setup is designed for internal use only.** No public IP address, no domain name, and no TLS certificate are required.
> If you want to expose the services publicly with HTTPS, refer to the [Traefik documentation](https://doc.traefik.io/traefik/) for Let's Encrypt configuration.

## What you'll build

```
LAN
 │
 ▼
Traefik (port 80) — password protected
 ├─ openclaw.local ──▶  OpenClaw gateway  (port 18789)
 └─ clawmetry.local ──▶  ClawMetry dashboard (port 8900)

Both services share ~/.openclaw (read-only for ClawMetry)
```

## Prerequisites

- A Linux machine on your local network
- [Docker Engine](https://docs.docker.com/engine/install/) ≥ 24 and Docker Compose v2
- `htpasswd` (from the `apache2-utils` package) **or** Docker (to generate the password hash)

## Step 1 — Run the OpenClaw onboarding wizard

[ClawMetry](https://clawmetry.com/) reads data written by the OpenClaw gateway. Before using the Traefik compose file you need to configure OpenClaw with its interactive setup wizard.

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

## Step 3 — Generate a password hash

Traefik uses **bcrypt-hashed** credentials for HTTP Basic Auth. Generate a hash for your chosen username and password:

**Option A — Using Docker (no extra packages needed):**

```bash
docker run --rm httpd:alpine htpasswd -nB admin
```

**Option B — Using `htpasswd` directly:**

```bash
# Install if needed: sudo apt install apache2-utils
htpasswd -nB admin
```

Both commands prompt for a password and print a line like:

```
admin:$2y$05$someLongHashStringHere...
```

> **Important:** Every `$` in the hash must be escaped as `$$` when placed in your `.env` file (Docker Compose variable substitution).
> Example: `$2y$05$abc` → `$$2y$$05$$abc` in `.env`

Copy the output and note it for the next step.

## Step 4 — Add hostnames to `/etc/hosts`

Traefik routes requests by hostname. Add two entries to `/etc/hosts` on every machine that needs access to the services (replace `192.168.1.100` with your server's actual LAN IP address):

```
192.168.1.100  openclaw.local
192.168.1.100  clawmetry.local
```

On Linux and macOS: `sudo nano /etc/hosts`

On Windows: edit `C:\Windows\System32\drivers\etc\hosts` as Administrator.

You can choose different hostnames — just keep them in sync with `OPENCLAW_DOMAIN` and `CLAWMETRY_DOMAIN` in your `.env` file.

## Step 5 — Create the `.env` file

Copy the example file from this repository:

```bash
cp /path/to/clawmetry-docker/.env.traefik.example .env
```

Fill in your values (paste the escaped hash from Step 3 into `TRAEFIK_BASICAUTH_USERS`):

```bash
# Hostnames — must match the entries you added to /etc/hosts
OPENCLAW_DOMAIN=openclaw.local
CLAWMETRY_DOMAIN=clawmetry.local

# Basic auth: paste your escaped bcrypt hash here ($ replaced with $$)
TRAEFIK_BASICAUTH_USERS=admin:$$2y$$05$$yourHashHere...

# Optional: your display name in the ClawMetry Flow tab
OPENCLAW_USER=
```

> **Tip:** Add `.env` to your `.gitignore` to avoid accidentally committing it.

## Step 6 — Create the `docker-compose.yml`

Copy [`docker-compose.traefik.yml`](https://github.com/stritti/clawmetry-docker/blob/main/docker-compose.traefik.yml) from this repository and rename it:

```bash
cp /path/to/clawmetry-docker/docker-compose.traefik.yml docker-compose.yml
```

Or create it with this content:

```yaml
services:

  # ─── Traefik reverse proxy (HTTP only) ──────────────────────────────────
  traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
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
      - "traefik.http.routers.openclaw.entrypoints=web"
      - "traefik.http.routers.openclaw.middlewares=auth@docker"
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
      - "traefik.http.routers.clawmetry.entrypoints=web"
      - "traefik.http.middlewares.auth.basicauth.users=${TRAEFIK_BASICAUTH_USERS}"
      - "traefik.http.routers.clawmetry.middlewares=auth"
      - "traefik.http.services.clawmetry.loadbalancer.server.port=8900"
    restart: unless-stopped
    networks:
      - proxy
      - internal

networks:
  proxy:
  internal:
    internal: true
```

## Step 7 — Fix file permissions

Both containers run as user `1000`. If your `~/.openclaw` directory was created by a different user, fix the ownership before starting the stack:

```bash
sudo chown -R 1000:1000 ~/.openclaw
```

## Step 8 — Start the stack

```bash
docker compose up -d
```

Check that all three containers are running:

```bash
docker compose ps
```

Expected output:

```
NAME                                   IMAGE                        STATUS
clawmetry-traefik-traefik-1            traefik:v3.0                 Up
clawmetry-traefik-openclaw-gateway-1   alpine/openclaw:latest       Up
clawmetry-traefik-clawmetry-1          stritti/clawmetry:latest     Up
```

## Step 9 — Connect OpenClaw to the gateway

Fetch the Control UI URL and paste your gateway token into **Settings → Token**:

```bash
docker compose exec openclaw-gateway openclaw-cli dashboard --no-open
```

Open the printed URL in your browser. When prompted by your browser (HTTP Basic Auth from Traefik), enter the username and password you set in Step 3. Once authenticated, you'll reach the OpenClaw Control UI — enter the gateway token from Step 1 in **Settings → Token**.

## Step 10 — Open the ClawMetry dashboard

Navigate to `http://clawmetry.local` (replace with the hostname you set in your `.env` and `/etc/hosts`).

Your browser will show a login prompt — enter the username and password you chose in Step 3.

The [ClawMetry](https://clawmetry.com/) dashboard shows live metrics, session recordings, and logs streamed from the shared `~/.openclaw` directory.

## Security considerations

| Topic | Recommendation |
|---|---|
| Password protection | Both services are protected by Traefik HTTP Basic Auth — always set a strong password. |
| Non-root containers | Both ClawMetry and OpenClaw run as user `1000` — never add `privileged: true`. |
| Read-only volume | ClawMetry mounts `~/.openclaw` with `:ro` — it cannot modify agent data. |
| Internal network | The `internal` network has no direct internet routing — containers communicate with each other but external traffic must pass through Traefik. |
| Direct port exposure | Never bind ports `8900` or `18789` directly on the host — always route through Traefik. |
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
