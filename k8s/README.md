*This directory is for personal home-server demo deployment only — not part of the 42 evaluation, which uses `docker-compose.yml` at the repo root.*

## What this is

Kubernetes manifests to run this project on a personal single-node microk8s cluster
(Cloudflare Tunnel + nginx-ingress, `public` namespace). Full step-by-step usage is
documented outside this repo (personal Obsidian vault, not committed here since it
contains personal infra details).

## What's NOT here

- No secret **values** — `Secret` objects (`transcendence-env`, `prometheus-basic-auth`)
  are created separately with `kubectl create secret --from-env-file=.env` /
  `--from-file=auth=...`, where `.env` and the htpasswd file stay local and untracked.
- No Cloudflare Tunnel config, no domain names beyond what appears in `ingress-*.yaml`
  (`Ingress.spec.rules[].host`).

## Files

| File | Contains |
|---|---|
| `pvc.yaml` | PersistentVolumeClaims for db/redis/grafana/uploads |
| `db.yaml` | PostgreSQL Deployment + Service |
| `redis.yaml` | Redis Deployment + Service |
| `backend.yaml` | Backend Deployment + Service `transcendence-backend` (image tag pinned to a release version) |
| `frontend.yaml` | Frontend Deployment + Service `transcendence-frontend` (image tag pinned to a release version) |
| `ingress-app.yaml` | Ingress routing the app's public hostname to frontend/backend |
| `monitoring.yaml` | Prometheus + Grafana Deployments + Services (optional, demo-only stack) |
| `ingress-monitoring.yaml` | Ingress for Grafana/Prometheus public hostnames |

## Naming

The `public` namespace on this cluster is shared with other personal projects.
`backend`/`frontend`/`db`/`redis` are generic names other projects may already own —
if a Service with the same name already exists, `kubectl apply` silently overwrites its
selector/ports, hijacking its traffic (this happened once to a co-tenant project's
`backend`/`frontend` Services, causing a live outage until reverted). Every Service in
this directory is namespaced with a `transcendence-` prefix for this reason; keep that
convention for anything added here.

## Updating image tags for a new release

`backend.yaml`/`frontend.yaml` pin `image:` to a specific tag (e.g. `v0.0.6`). When
cutting a new release, bump those two lines to match the new tag as part of the same
commit/PR that tags the release, so `k8s/` always reflects a working combination of
manifests + image versions for that tag.

## Apply

```bash
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/db.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/frontend.yaml
kubectl apply -f k8s/ingress-app.yaml
kubectl apply -f k8s/monitoring.yaml            # optional
kubectl apply -f k8s/ingress-monitoring.yaml    # optional
```
(Secrets and ConfigMaps must exist first — see the personal deployment runbook.)
