# Traefik + OpenClaw + ClawMetry (Internal Setup)

This guide shows how to run **OpenClaw** and **[ClawMetry](https://clawmetry.com/)** together on a Raspberry Pi or home-lab machine using Traefik as a reverse proxy. Both services are served from a **single local hostname** on **HTTPS**, protected by a **login password**:

| URL | Service |
|---|---|
| `https://openclaw.local` | OpenClaw gateway (Control UI) |
| `https://openclaw.local/stats` | [ClawMetry](https://clawmetry.com/) dashboard |

> **Internal use only.** Traefik generates a self-signed TLS certificate automatically — no public IP, no domain registration, and no Let's Encrypt required. Your browser will show a security warning on first visit; add a certificate exception once and you will not see it again.

## What you'll build

```
LAN
 │
 ▼
Traefik (port 80 → 443 redirect, HTTPS with self-signed cert)
 │  — password protected (HTTP Basic Auth) —
 ├─ openclaw.local        ──▶  OpenClaw gateway  (port 18789)
 └─ openclaw.local/stats  ──▶  ClawMetry dashboard (port 8900)

Both services share ~/.openclaw (read-only for ClawMetry)
```

## Prerequisites

- A Linux machine on your local network (e.g. a Raspberry Pi)
- [Docker Engine](https://docs.docker.com/engine/install/) ≥ 24 and Docker Compose v2
- `htpasswd` (from `apache2-utils`) **or** Docker (to generate the password hash)

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

## Step 4 — Add the hostname to `/etc/hosts`

Add one line to `/etc/hosts` on every machine that needs access to the services
(replace `192.168.1.100` with your Pi's actual LAN IP address):

```
192.168.1.100  openclaw.local
```

On Linux and macOS: `sudo nano /etc/hosts`

On Windows: edit `C:\Windows\System32\drivers\etc\hosts` as Administrator.

You can choose a different hostname — just keep it in sync with `DOMAIN` in your `.env` file.

## Step 5 — Create the `.env` file

Copy the example file from this repository:

```bash
cp /path/to/clawmetry-docker/.env.traefik.example .env
```

Fill in your values (paste the escaped hash from Step 3 into `TRAEFIK_BASICAUTH_USERS`):

```bash
# Local hostname — must match the entry you added to /etc/hosts
DOMAIN=openclaw.local

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
      # HTTPS with auto-generated self-signed certificate (no certresolver)
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
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
      - "traefik.http.routers.openclaw.rule=Host(`${DOMAIN}`)"
      - "traefik.http.routers.openclaw.entrypoints=websecure"
      - "traefik.http.routers.openclaw.tls=true"
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
      # Tells ClawMetry it is mounted at /stats (for correct URL generation)
      SCRIPT_NAME: "/stats"
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=proxy"
      # PathPrefix rule has higher priority than the bare Host rule above
      - "traefik.http.routers.clawmetry.rule=Host(`${DOMAIN}`) && PathPrefix(`/stats`)"
      - "traefik.http.routers.clawmetry.entrypoints=websecure"
      - "traefik.http.routers.clawmetry.tls=true"
      # Strip /stats before forwarding to ClawMetry
      - "traefik.http.middlewares.stats-strip.stripprefix.prefixes=/stats"
      - "traefik.http.middlewares.auth.basicauth.users=${TRAEFIK_BASICAUTH_USERS}"
      - "traefik.http.routers.clawmetry.middlewares=auth,stats-strip"
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

## Step 9 — Accept the self-signed certificate

Open `https://openclaw.local` in your browser. Because Traefik uses a self-signed certificate, your browser will show a security warning ("Your connection is not private" or similar).

Click **Advanced → Proceed** (Chrome) or **Accept the Risk and Continue** (Firefox) to add a permanent exception. You only need to do this once per browser.

## Step 10 — Connect OpenClaw to the gateway

Fetch the Control UI URL and paste your gateway token into **Settings → Token**:

```bash
docker compose exec openclaw-gateway openclaw-cli dashboard --no-open
```

Open the printed URL in your browser. When prompted by your browser (HTTP Basic Auth from Traefik), enter the username and password you set in Step 3. Once authenticated, you'll reach the OpenClaw Control UI — enter the gateway token from Step 1 in **Settings → Token**.

## Step 11 — Open the ClawMetry dashboard

Navigate to `https://openclaw.local/stats` (replace `openclaw.local` with the `DOMAIN` you set).

Your browser will show the same login prompt — enter the username and password from Step 3.

The [ClawMetry](https://clawmetry.com/) dashboard shows live metrics, session recordings, and logs streamed from the shared `~/.openclaw` directory.

## Security considerations

| Topic | Recommendation |
|---|---|
| Password protection | Both services are protected by Traefik HTTP Basic Auth — always set a strong password. |
| Self-signed certificate | The TLS certificate is self-signed and will trigger a browser warning. Add an exception once. Never expose this setup on a public network. |
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
