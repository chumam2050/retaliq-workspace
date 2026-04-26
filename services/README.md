# Service Infrastructure

This directory contains the Docker Compose configuration for the foundational services of the Retaliq environment.

## 🏗️ Services Overview

Access these services via the automatic HTTPS proxy provided by Caddy.

| Service | Container Name | Version | Internal Port | External URL (Local) |
| :--- | :--- | :--- | :--- | :--- |
| **Gateway** | `caddy` | Alpine | 80/443 | `https://localhost` |
| **Database (Main)** | `mariadb` | 10.11 | 3306 | - |
| **Database (Apps)** | `postgres` | 16 | 5432 | - |
| **Object Storage** | `minio` | Latest | 9000/9001 | [Console](https://minio.localhost) / [API](https://s3.localhost) |
| **Cache/Queue** | `redis` | Alpine | 6379 | - |
| **WebSockets** | `soketi` | Latest | 6001 | [https://ws.localhost](https://ws.localhost) |
| **Mail Server** | `stalwart` | Latest | 25, 143, etc. | [Admin](https://mail.localhost) |
| **Error Tracking** | `glitchtip` | v6 | 8000 | [https://glitchtip.localhost](https://glitchtip.localhost) |
| **Security Scanner** | `nettacker` | Latest | 5000 | [https://localhost:5000](https://localhost:5000) |

> **Note:** Domains like `*.localhost` must resolve to `127.0.0.1`. See the main README for hosts file configuration.

---

## 🔐 Credentials (Default)

These are the default credentials configured in `.env`. **Do not use in production.**

### PostgreSQL
Used by Soketi, Stalwart, and GlitchTip.
- **Host:** `postgres`
- **User:** `app_user`
- **Password:** `secure_pg_password`
- **Port:** `5432`

### MariaDB
Main application database.
- **Host:** `mariadb`
- **Root Password:** `secure_root_password`
- **User:** `app_user`
- **Password:** `secure_user_password`
- **Database:** `app_db`

### MinIO (S3 Compatible)
Object storage for file uploads.
- **Console User:** `minioadmin`
- **Console Password:** `minioadmin`
- **Region:** `us-east-1` (Default)
- **Buckets:** `stalwart`, `glitchtip` (Auto-created)

### GlitchTip
Sentry-compatible error tracking.
- **URL:** `https://glitchtip.localhost`
- **Admin Email:** `glitchtip@localhost` (You must register the first user)
- **DSN:** Generated in the UI after creating a project.

---

## 🛠️ Service Details

### Soketi (WebSockets)
A fast, resilient WebSocket server compatible with Pusher.
- **App ID:** `app-id`
- **App Key:** `app-key`
- **App Secret:** `app-secret`
- **Driver:** PostgreSQL

### Stalwart (Mail Server)
All-in-one mail server (SMTP, IMAP, JMAP).
- **Web Admin:** `https://mail.localhost` (Default login: `admin` / `password` - check logs if unsure)
- **Storage:** Metadata in Postgres, Blobs in MinIO.

### GlitchTip
Open source error tracking, compatible with Sentry SDKs.
- **Worker:** Runs background jobs via Redis.
- **Migrate:** Runs DB migrations on startup.

### OWASP Nettacker
Automated security testing framework with REST API and Web UI.
- **URL:** `https://localhost:5000`
- **Persistence:** Scan DB and reports are stored in `services/nettacker/data`.
- **Run a scan from container:** `docker exec -it nettacker poetry run python ./nettacker.py -i scanme.nmap.org -m port_scan`
