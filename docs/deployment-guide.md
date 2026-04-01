# Deployment Guide — Avisbop

## Architecture Overview

```
┌─────────────────────────────────┐
│        Google Cloud Run         │
│   (Rails Web App - Port 8080)   │
│   Auto-scaling containers       │
│   Image: gcr.io/PROJECT/SERVICE │
└──────────────┬──────────────────┘
               │ Enqueue jobs via Solid Queue
               ▼
┌─────────────────────────────────┐
│     Google Cloud SQL            │
│   (PostgreSQL - budgetlab)      │
│   Region: europe-west1         │
│   Connection: Cloud SQL Proxy   │
│   Databases: primary + queue    │
└──────────────┬──────────────────┘
               │ Polling for jobs
               ▼
┌─────────────────────────────────┐
│      GCP VM (anaco-workers)     │
│   IP: 34.163.126.114            │
│   Managed by: Kamal             │
│   Docker containers:            │
│   - Solid Queue Workers (x4)    │
│   - Chromium for PDF generation │
│   - Cloud SQL Proxy sidecar     │
└─────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│   Google Cloud Storage          │
│   Bucket: anaco-bucket          │
│   Active Storage attachments    │
│   PDF files, documents          │
└─────────────────────────────────┘
```

---

## CI/CD Pipeline

### GitHub Actions (Testing & Linting)

**Trigger:** Push to `main` or PR targeting `main`.

**Jobs:**

1. **test** — Runs on ubuntu-latest with PostgreSQL 11
   - Ruby 3.4 setup with bundler cache
   - `bin/rails db:schema:load`
   - `bin/rake` (all tests)

2. **lint** — Security scanning
   - `bundle exec bundle audit --update` (dependency vulnerabilities)
   - `bundle exec brakeman -q -w2` (static code analysis)
   - RuboCop (currently disabled)

**Secrets required:** `RAILS_MASTER_KEY_ANACO`

### Google Cloud Build (Deployment)

**File:** `cloudbuild.yaml`

**Steps:**
1. **Build image** — Docker build with `MASTER_KEY` secret
2. **Push image** — Push to Google Container Registry (`gcr.io`)
3. **Apply migrations** — Run `db:migrate` via Cloud SQL exec wrapper

**Substitutions:**
- `_REGION`: europe-west1
- `_SERVICE_NAME`: anaco-test
- `_INSTANCE_NAME`: budgetlab
- `_PRODUCTION_DB_NAME`: anaco-test
- `_CLOUD_SQL_CONNECTION_NAME`: apps-354210:europe-west1:budgetlab

---

## Docker Configuration

### Web App (Dockerfile)

- **Base:** Ruby 3.4
- **Installs:** Node.js 18, npm, Yarn, Google Chrome
- **Precompiles:** Rails assets with dummy secret key
- **Exposes:** Port 8080
- **Entrypoint:** `bin/rails server`

### Workers (Dockerfile.workers)

- **Base:** Ruby 3.4-slim (multi-stage build)
- **Build stage:** Installs build dependencies, compiles gems
- **Final stage:** Installs Node.js 20, Chromium, runtime dependencies
- **Precompiles:** Assets with dummy key
- **Entrypoint:** `./bin/jobs` (Solid Queue workers)

Key difference: Workers need Chromium/Puppeteer for PDF generation (Grover).

---

## Kamal Deployment (Workers)

### Configuration

**File:** `config/deploy.yml`

```yaml
service: anaco-workers
image: alexandraleschi/anaco-workers
servers:
  workers:
    hosts: ["34.163.126.114"]
    cmd: ./bin/jobs
```

**Environment variables:**
- `JOB_CONCURRENCY`: 4
- `PUPPETEER_EXECUTABLE_PATH`: /usr/bin/chromium
- `RAILS_ENV`: production
- `STORAGE_BUCKET_NAME`: anaco-bucket

### Deployment Commands

```bash
# First deployment
kamal setup

# Subsequent deployments
kamal deploy

# Force rebuild
kamal deploy --force

# View logs
kamal app logs -f

# Restart workers
kamal app restart

# Rails console on worker
kamal app exec -i "bin/rails console"

# Container details
kamal app details
```

### Secrets

Located in `.kamal/secrets` (gitignored). Required values:
- `KAMAL_REGISTRY_PASSWORD` — Docker Hub authentication
- `SECRET_KEY_BASE` — Rails secret (generate with `rails secret`)
- `DATABASE_URL` — PostgreSQL connection URL
- `RAILS_MASTER_KEY` — From `config/master.key`

---

## Database Configuration

### Production (Cloud SQL)

Two databases on the same PostgreSQL instance:
1. **primary** — Application data
2. **queue** — Solid Queue job data (same connection config)

Connection routing:
- **Cloud Run** → Cloud SQL Proxy socket at `/cloudsql/apps-354210:europe-west1:budgetlab`
- **Kamal Workers** → Cloud SQL Proxy container (`anaco-workers-cloud-sql-proxy`) on port 5432

Toggle via `USE_CLOUD_SQL_PROXY` environment variable.

### Migrations

```bash
# Local
bin/rails db:migrate

# Production (via Cloud Build)
# Automatically run in cloudbuild.yaml step "apply migrations"

# Manual production migration
kamal app exec "bin/rails db:migrate"
```

---

## Storage Configuration

### Google Cloud Storage

- **Project:** apps-354210
- **Bucket:** anaco-bucket
- **Service:** Configured in `config/storage.yml` as `:google`
- **Credentials:** Via service account JSON or GCP metadata

Active Storage routes are prefixed at `/anaco/rails/active_storage`.

---

## Monitoring

### Application Logs

```bash
# Cloud Run logs (via GCP Console)
# Navigate to: Cloud Run > anaco-test > Logs

# Worker logs
kamal app logs --follow

# Local development
tail -f log/development.log
```

### Worker Health

```bash
# SSH to worker VM
ssh root@34.163.126.114

# Docker stats
docker stats

# System resources
htop

# Docker container logs
journalctl -u docker -f
```

---

## Environment Variables Summary

| Variable | Used By | Purpose |
|----------|---------|---------|
| PRODUCTION_DB_NAME | App + Workers | PostgreSQL database name |
| PRODUCTION_DB_USERNAME | App + Workers | Database user |
| PRODUCTION_DB_PASSWORD | App + Workers | Database password |
| CLOUD_SQL_CONNECTION_NAME | App + Workers | GCP Cloud SQL instance |
| USE_CLOUD_SQL_PROXY | Workers | Toggle proxy vs socket connection |
| GOOGLE_PROJECT_ID | App + Workers | GCP project identifier |
| STORAGE_BUCKET_NAME | App + Workers | GCS bucket name |
| SERVICE_NAME | Cloud Build | Service identifier |
| RAILS_MASTER_KEY | App + Workers | Credentials decryption |
| SECRET_KEY_BASE | App + Workers | Rails session encryption |
| KAMAL_REGISTRY_PASSWORD | Kamal | Docker Hub authentication |
| JOB_CONCURRENCY | Workers | Solid Queue thread count |
| PUPPETEER_EXECUTABLE_PATH | Workers | Chromium binary path |
| RAILS_ENV | All | Environment (production/development/test) |
| APP_URL | Workers | Base URL for PDF CSS/image loading |

---

## Troubleshooting

### Workers Not Starting
```bash
kamal app logs --tail 100
kamal app exec "env | grep RAILS"
kamal app restart
```

### PDF Generation Failing
- Verify Chromium is installed: `kamal app exec "which chromium"`
- Check `PUPPETEER_EXECUTABLE_PATH` is set correctly
- Review Grover config in `config/initializers/grover.rb`

### Database Connection Issues
- Cloud Run: Check Cloud SQL connection name in environment
- Workers: Verify Cloud SQL Proxy sidecar is running
- Check `USE_CLOUD_SQL_PROXY` environment variable

### Asset Compilation
```bash
# Force recompile
bin/rails assets:clobber
bin/rails assets:precompile
```
