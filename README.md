# Retaliq Monorepo

Docker-first local development for Retaliq services and apps.

This README intentionally focuses on:

- `services/` (shared infrastructure)
- `apps/` (application containers)

Other folders (CLI internals, pentest utilities, docs details) are out of scope for now.

## What Runs Here

### Shared services (`services/compose.yml`)

- `caddy` (gateway + TLS for local domains)
- `postgres`, `mariadb`, `redis`
- `minio` + `minio-init`
- `soketi`
- `stalwart` + `roundcube`
- `glitchtip`

### Apps (`apps/*/compose*.ya?ml`)

- `apps/retaliq`
- `apps/umkm`

Each app joins the shared external Docker network: `retaliq-net`.

## Prerequisites

- Docker Engine + Docker Compose plugin
- Linux/macOS shell (or WSL on Windows)
- `go` (only needed if you want to build/update the `retaliq` CLI binary)

## Quick Start (Docker-first)

1. Prepare environment files.

```bash
cp services/.env.example services/.env
cp apps/retaliq/.env.example apps/retaliq/.env
cp apps/umkm/.env.example apps/umkm/.env
```

2. Start infrastructure services.

```bash
docker compose -f services/compose.yml up -d
```

3. Start app containers.

```bash
docker compose -f apps/retaliq/compose.dev.yaml up -d
docker compose -f apps/umkm/compose.yaml up -d
```

4. Check running containers.

```bash
docker ps
```

## Local Domains and Access

Default domain base in `services/.env` is usually `DOMAIN_NAME=localhost`.

Primary app domains:

- `https://retaliq.localhost`
- `https://umkm.localhost`

Selected service domains:

- `https://minio.localhost` (console)
- `https://s3.localhost` (S3 endpoint)
- `https://ws.localhost` (websocket gateway)
- `https://mail.localhost` (mail admin)
- `https://glitchtip.localhost` (error tracking)

If your environment needs host mapping, ensure these domains resolve to `127.0.0.1`.

## Daily Commands

Start all (services + apps):

```bash
docker compose -f services/compose.yml up -d
docker compose -f apps/retaliq/compose.dev.yaml up -d
docker compose -f apps/umkm/compose.yaml up -d
```

Stop all:

```bash
docker compose -f apps/umkm/compose.yaml down
docker compose -f apps/retaliq/compose.dev.yaml down
docker compose -f services/compose.yml down
```

Restart all:

```bash
docker compose -f apps/umkm/compose.yaml down
docker compose -f apps/retaliq/compose.dev.yaml down
docker compose -f services/compose.yml down
docker compose -f services/compose.yml up -d
docker compose -f apps/retaliq/compose.dev.yaml up -d
docker compose -f apps/umkm/compose.yaml up -d
```

Tail logs:

```bash
docker logs -f caddy
docker logs --tail 200 postgres
```

Manage one container by name:

```bash
docker start redis
docker restart caddy
docker logs -f glitchtip
```

## Development Scope (Current)

For now, project-level development and onboarding should prioritize:

- shared service reliability under `services/`
- app runtime and integration under `apps/`

Keep changes outside these areas minimal unless explicitly requested.
