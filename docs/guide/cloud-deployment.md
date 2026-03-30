# Cloud Deployment

Run the [ClawMetry](https://clawmetry.com/) dashboard on a remote server and access it from anywhere.

---

## Option 1: VPS / Cloud VM (Recommended)

Any Linux VM works: DigitalOcean, Hetzner, AWS EC2, GCP Compute Engine, etc.

### 1. Install Docker

Follow the [official Docker installation guide](https://docs.docker.com/engine/install/) for your distro, then start the dashboard:

```bash
docker run -d \
  --name clawmetry \
  -p 8900:8900 \
  -v /path/to/openclaw/agent:/home/clawmetry/.openclaw \
  stritti/clawmetry:latest
```

If your OpenClaw workspace is on a different machine, mount or sync it first, then pass the path:

```bash
docker run -d \
  --name clawmetry \
  -p 8900:8900 \
  -v /path/to/openclaw/agent:/workspace \
  stritti/clawmetry:latest --workspace /workspace
```

### 2. Secure access

**SSH tunnel (simplest — no firewall rule needed):**

```bash
# From your laptop:
ssh -L 8900:localhost:8900 user@your-server
# Then open http://localhost:8900
```

**Reverse proxy with nginx (production):**

```nginx
# /etc/nginx/sites-available/clawmetry
server {
    listen 443 ssl;
    server_name dashboard.yourdomain.com;

    ssl_certificate     /etc/letsencrypt/live/dashboard.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.yourdomain.com/privkey.pem;

    # SSE needs long timeouts and buffering disabled
    proxy_read_timeout 600s;
    proxy_buffering    off;

    location / {
        auth_basic           "ClawMetry Dashboard";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass           http://127.0.0.1:8900;
        proxy_set_header     Host      $host;
        proxy_set_header     X-Real-IP $remote_addr;
    }
}
```

**Reverse proxy with Caddy (auto-HTTPS):**

```
dashboard.yourdomain.com {
    basicauth * {
        admin $2a$14$... # caddy hash-password
    }
    reverse_proxy localhost:8900
}
```

---

## Option 2: Google Cloud Run (Serverless)

Ideal when your OpenClaw metrics are sent via OTLP.

> **Note:** Cloud Run is stateless — file-based features (logs, transcripts, memory) require a mounted volume. For token/cost dashboards without local file access see [OTLP-only mode](#otlp-only-mode-metrics-without-workspace) below.

### 1. Deploy

Use the pre-built image directly — no local build needed:

```bash
gcloud run deploy clawmetry \
  --image stritti/clawmetry:latest \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8900 \
  --memory 512Mi
```

### 2. Send OTLP data

Point your OpenClaw config at the Cloud Run URL:

```yaml
diagnostics:
  otel:
    endpoint: https://clawmetry-xxxxx.run.app
```

The **Usage** tab and health checks will work. For the full feature set, run on a VM with the workspace mounted.

---

## Option 3: Railway / Render / Fly.io

These platforms all support Docker images directly.

### Railway

Create a `railway.json` in your project root:

```json
{
  "build": { "builder": "DOCKERFILE" },
  "deploy": {
    "startCommand": null
  }
}
```

Then deploy using the `stritti/clawmetry:latest` Docker image and set the `PORT` variable to `8900` in the Railway dashboard.

### Fly.io

```bash
fly launch --image stritti/clawmetry:latest
```

In the generated `fly.toml`, set the internal port to `8900`:

```toml
[[services]]
  internal_port = 8900
  protocol      = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port     = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port     = 443
```

### Render

1. Create a new **Web Service** in the Render dashboard.
2. Choose **Deploy an existing image** and enter `stritti/clawmetry:latest`.
3. Set the **Port** to `8900`.
4. Add any [environment variables](/guide/configuration) you need (e.g. `OPENCLAW_DATA_DIR`).

---

## OTLP-Only Mode (Metrics Without Workspace)

If you only want cost/token dashboards without local file access, the dashboard runs in "OTLP-only" mode — no workspace volume required:

```bash
docker run -d \
  --name clawmetry \
  -p 8900:8900 \
  stritti/clawmetry:latest
```

Configure OpenClaw to send metrics:

```yaml
diagnostics:
  otel:
    endpoint: http://your-dashboard-host:8900
```

You get: **Usage** tab (tokens, costs, model breakdown), health checks, and the **Flow** visualisation. Tabs that need local files (Logs, Memory, Transcripts) show empty states gracefully.

---

## Custom Port

The container defaults to port `8900`. Override it with an environment variable:

```bash
docker run -d \
  -p 9000:9000 \
  -e OPENCLAW_DASHBOARD_PORT=9000 \
  stritti/clawmetry:latest
```

Or via a CLI flag:

```bash
docker run -d \
  -p 9000:9000 \
  stritti/clawmetry:latest --port 9000
```

---

## Troubleshooting

| Issue | Fix |
|---|---|
| SSE streams disconnect | Set `proxy_read_timeout 600s` and `proxy_buffering off` in nginx |
| Empty tabs on Cloud Run | Expected — mount a volume or use OTLP-only mode |
| Port already in use | Set `OPENCLAW_DASHBOARD_PORT=9000` or pass `--port 9000` |
| High memory on long runs | Metrics auto-cap at ~10 K entries per category |

---

## See also

- [Configuration reference](/guide/configuration) — all supported environment variables
- [Docker Compose](/guide/docker-compose) — run ClawMetry alongside the OpenClaw gateway
- [Traefik + OpenClaw](/guide/traefik) — HTTPS + password-protected home-lab setup
