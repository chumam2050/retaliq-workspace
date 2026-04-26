# AGENTS

Workspace guidance for AI/code agents in this repository.

## Active Scope

Current focus is Docker-first development for:

- `services/`
- `apps/`

Treat other top-level directories as out of scope unless explicitly requested.

## Primary Runtime Model

- Shared infrastructure is managed from `services/compose.yml`.
- App containers are managed from each app directory under `apps/`.
- All app and service containers use the external Docker network `retaliq-net`.

## Preferred Commands

Use standard Docker commands:

- `docker compose -f services/compose.yml up -d`
- `docker compose -f services/compose.yml down`
- `docker compose -f apps/<app>/compose.yaml up -d`
- `docker compose -f apps/<app>/compose.yaml down`
- `docker ps`
- `docker logs -f <container>`

Use `retaliq` CLI only for non-docker operations (db/minio/redis/soketi/caddy/stalwart/glitchtip/domain) when needed.

## Environment Files

Before booting stacks, ensure these files exist:

- `services/.env` (from `services/.env.example`)
- app-level `.env` files in each folder under `apps/` as needed

Do not commit secrets. Use local overrides for machine-specific values.

## Change Boundaries

When asked to update docs or setup:

- document service/app flow first
- keep examples runnable on Linux Docker environments
- avoid changing unrelated architecture notes

When asked to edit code:

- prefer minimal changes inside `services/` and `apps/`
- do not refactor unrelated directories by default
