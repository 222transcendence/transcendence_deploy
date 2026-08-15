*This directory is for personal home-server deployment only — not part of the 42
evaluation, which uses `docker-compose.yml`/`nginx/` at the repo root as-is.*

## What this is

An override layer on top of the root `docker-compose.yml`, for running this project
directly on a personal server (Z2 mini) with router port forwarding (80/443 only) —
no Kubernetes, no Cloudflare Tunnel. `nginx` is the only container with a host port
published; everything else binds to `127.0.0.1` only, and Grafana/Prometheus are
reachable through the same nginx container under `/grafana/`/`/prometheus/` on the
same domain (`acidrain.hijae.dev`) instead of separate subdomains, so only one DNS
record is needed.

## What's NOT here

- No secret values — `.env` (read by the root `docker-compose.yml` via `${VAR}`
  interpolation) and `homelab/prometheus.htpasswd` stay local and untracked.
- No DNS/router config, no TLS certificates.

## Files

| File | Contains |
|---|---|
| `docker-compose.override.yml` | Rebinds host ports to `127.0.0.1` (except nginx), adds Grafana/Prometheus subpath config, mounts `nginx-homelab.conf` + htpasswd into the nginx container |
| `nginx-homelab.conf` | Full nginx config (not a diff) — same routing as the root `nginx/nginx.conf` plus `/grafana/`, `/prometheus/` (Basic Auth) location blocks. Replaces the built-in config via a volume mount; the image's own `nginx/nginx.conf` is untouched |

## Usage

```bash
docker compose -f docker-compose.yml -f homelab/docker-compose.override.yml up -d --build
```

Full step-by-step (port forwarding, DNS, htpasswd, .env) is documented outside this
repo (personal Obsidian vault, not committed here since it contains personal infra
details).
