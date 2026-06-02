# Noema Runtime Inventory

This inventory records the current Forem-derived runtime surfaces in the `agentwego/noema` fork. It is intended to guide the first Kubernetes/GitOps packaging spike without committing any real secrets.

## Sources Inspected

- `Dockerfile`
- `Containerfile`
- `Procfile`
- `Procfile.dev`
- `docker-compose.yml`
- `container-compose.yml`
- `config/deploy.yml`
- `scripts/entrypoint.sh`
- `release-tasks.sh`
- `.env_sample`
- `config/database.yml`
- `config/puma.rb`
- `config/initializers/0_application_config.rb`
- `config/initializers/sidekiq.rb`
- `config/initializers/carrierwave.rb`
- `config/initializers/1_imgproxy.rb`
- `app/services/images/optimizer.rb`
- `app/services/agent_sessions/s3_storage.rb`
- `lib/tasks/app_initializer.rake`
- `lib/tasks/forem.rake`
- `lib/tasks/fastly.rake`

## Container Image Baseline

### Dockerfile / Containerfile

Both root `Dockerfile` and `Containerfile` currently define the same multi-stage build shape:

- `base`: `ghcr.io/forem/ruby:3.3.0@sha256:9cda49a45931e9253d58f7d561221e43bd0d47676b8e75f55862ce1e9997ab5c`
- `builder`: installs build dependencies, bundle, yarn dependencies, precompiles assets
- `production`: final runtime image
- `testing`
- `uffizzi`
- `development`

Production image details:

- app user: `forem` UID/GID `1000`
- app home: `/opt/apps/forem`
- entrypoint: `./scripts/entrypoint.sh`
- default command: `bundle exec rails server -b 0.0.0.0 -p 3000`
- exposed app port: `3000`
- declares `VOLUME /opt/apps/forem/public/`

Noema note: the image and internal paths still use Forem naming. Do not mass-rename paths before the runtime spike; the safer first change is to publish a `noema` image while preserving internal compatibility paths.

## Process Commands

### Production-style Procfile

From `Procfile`:

```procfile
release: ./release-tasks.sh
web: bundle exec puma -C config/puma.rb
sidekiq_worker: bundle exec sidekiq -t 25
```

### Docker default web command

From `Dockerfile` / `Containerfile` production stage:

```bash
bundle exec rails server -b 0.0.0.0 -p 3000
```

For Kubernetes, prefer the Procfile web command because it uses explicit Puma config:

```bash
bundle exec puma -C config/puma.rb
```

### Worker command

```bash
bundle exec sidekiq -t 25
```

Development compose uses the simpler command:

```bash
bundle exec sidekiq
```

### Release / migration command

`release-tasks.sh` currently does:

```bash
STATEMENT_TIMEOUT=4500000 bundle exec rails app_initializer:setup
bundle exec rake fastly:update_configs
bundle exec rails runner "puts 'app load success'"
```

`scripts/entrypoint.sh bootstrap` also maps to:

```bash
bundle exec rake app_initializer:setup
```

`app_initializer:setup` performs:

- `bin/rails db:prepare` unless `SKIP_MIGRATIONS=yes`
- `release:migrate_if_pending`
- `forem:setup`
- `data_updates:enqueue_data_update_worker`
- cache-bust enqueueing
- initializes `Settings::General.health_check_token`

`fastly:update_configs` is safe when Fastly credentials are absent: it logs and exits unless both `FASTLY_API_KEY` and `FASTLY_SERVICE_ID` are present, and can be disabled with `SKIP_FASTLY_CONFIG_UPDATE=true`.

Kubernetes recommendation:

```bash
./release-tasks.sh
```

as a pre-rollout/Helm hook Job, with:

```text
SKIP_FASTLY_CONFIG_UPDATE=true
```

for the PoC unless Fastly is explicitly configured.

## Puma / Web Concurrency

From `config/puma.rb`:

- `PORT`, default `3000`
- `RAILS_ENV`, default `development`
- `RAILS_MAX_THREADS`, default `5`
- `WEB_CONCURRENCY`, default `2`
- uses `preload_app!`
- worker boot re-establishes ActiveRecord connections

From `config/database.yml`:

- DB pool is `RAILS_MAX_THREADS + 5`
- `connect_timeout`: `6`
- `checkout_timeout`: `10`
- `idle_timeout`: `60`
- `statement_timeout`: `STATEMENT_TIMEOUT`, default `2500` ms
- production URL: `NEW_DATABASE_URL` if set, else `DATABASE_URL`
- production disables prepared statements
- schema search path includes `"$user",public,heroku_ext`

PoC resource recommendation:

- `WEB_CONCURRENCY=1`
- `RAILS_MAX_THREADS=5`
- DB pool per web pod: about `10`
- worker concurrency can use Sidekiq default unless we explicitly set `-c`; start conservatively.

## Required Environment Variables for PoC

Clear/non-secret values:

```text
PORT=3000
RAILS_ENV=production
NODE_ENV=production
RAILS_SERVE_STATIC_FILES=true
APP_PROTOCOL=https://
APP_DOMAIN=noema.agentwego.com
COMMUNITY_NAME=Noema
DEFAULT_EMAIL=<sender address or placeholder>
FORCE_SSL_IN_RAILS=true
SKIP_FASTLY_CONFIG_UPDATE=true
WEB_CONCURRENCY=1
RAILS_MAX_THREADS=5
MALLOC_ARENA_MAX=2
```

Secrets / generated values:

```text
RAILS_MASTER_KEY
FOREM_OWNER_SECRET
DATABASE_URL
REDIS_URL
REDIS_SIDEKIQ_URL
REDIS_SESSIONS_URL
REDIS_RPUSH_URL
SESSION_KEY
```

Notes:

- The code has Redis URL normalization in `ApplicationConfig`; it rewrites unresolvable Redis hostnames to localhost. In production, Kubernetes service DNS should resolve, otherwise this fallback could hide a broken Redis URL. Verify Redis DNS from the pod before first boot.
- Existing Redis supports separate logical DBs by URL path. Suggested split for PoC follows `config/deploy.yml`: cache `/1`, sidekiq `/3`, sessions `/4`, rpush `/5`, adjusted for the real Redis auth URL.
- Do not commit real Redis or database URLs.

## Database Runtime

Primary env vars:

```text
DATABASE_URL
NEW_DATABASE_URL  # optional override that wins in production
DATABASE_POOL_SIZE # present in .env_sample but current database.yml primarily uses RAILS_MAX_THREADS + 5
STATEMENT_TIMEOUT
RAILS_ADVISORY_LOCKS
```

Required PostgreSQL extensions already observed in cluster reconnaissance:

- `hstore`
- `pg_trgm`
- `vector`

PoC database target:

```text
database: noema
user: noema
provider: existing CNPG app-db
```

## Redis Runtime

Primary env vars:

```text
REDIS_URL
REDIS_SIDEKIQ_URL
REDIS_SESSIONS_URL
REDIS_RPUSH_URL
REDISCLOUD_URL # production cache fallback before REDIS_URL in production.rb
```

Consumers:

- Rails cache: `REDISCLOUD_URL` or `REDIS_URL`
- ActionCable: `REDIS_URL`
- Sidekiq: `REDIS_SIDEKIQ_URL` or `REDIS_URL`
- Sessions: `REDIS_SESSIONS_URL` or `REDIS_URL`
- Rpush: `REDIS_RPUSH_URL` or `REDIS_URL`

## Uploads / Object Storage

CarrierWave production config currently switches to fog/AWS only when:

```text
RAILS_ENV=production
FILE_STORAGE_LOCATION != file
AWS_ID is present
```

Current upload-related env vars from `.env_sample`:

```text
AWS_ID
AWS_SECRET
AWS_BUCKET_NAME
AWS_UPLOAD_REGION
AWS_S3_INPUT_BUCKET
AWS_S3_VIDEO_ID
AWS_S3_VIDEO_KEY
```

Current CarrierWave AWS credentials only include:

```ruby
provider: "AWS"
aws_access_key_id: ApplicationConfig["AWS_ID"]
aws_secret_access_key: ApplicationConfig["AWS_SECRET"]
region: ApplicationConfig["AWS_UPLOAD_REGION"].presence || ApplicationConfig["AWS_DEFAULT_REGION"]
```

Current gap for S3-compatible storage:

- no explicit endpoint URL in `carrierwave.rb`
- no explicit path-style / force-path-style option
- `AgentSessions::S3Storage` has the same AWS-only credential shape
- video direct upload initializer has bucket/key fields but region is hardcoded `nil`

Conclusion: Onidel/S3-compatible storage should be treated as **not yet proven**. First either run a live MinIO/endpoint spike or patch support for:

```text
AWS_ENDPOINT_URL
AWS_FORCE_PATH_STYLE
AWS_DEFAULT_REGION
```

without breaking native AWS S3 defaults.

## Image Optimization

Relevant env vars:

```text
IMGPROXY_KEY
IMGPROXY_SALT
IMGPROXY_ENDPOINT
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
CLOUDINARY_CLOUD_NAME
CLOUDFLARE_IMAGES_DOMAIN
```

`Images::Optimizer` priority:

1. imgproxy, if key and salt are present
2. Cloudinary, if configured and not contextually bypassed
3. Cloudflare Images, if configured
4. raw URL fallback

Production imgproxy endpoint defaults to same-domain `/images` via `URL.url("images")`. For Kubernetes PoC, either:

- leave imgproxy disabled initially, or
- deploy imgproxy and route `/images` to it consistently.

## Search Runtime

Current env vars:

```text
ALGOLIA_APPLICATION_ID
ALGOLIA_API_KEY
ALGOLIA_SEARCH_ONLY_API_KEY
ALGOLIA_DISPLAY_BRANDING
```

Current implementation references:

- `config/initializers/algoliasearch.rb`
- `app/models/settings/general.rb`
- `app/controllers/search_controller.rb`
- `app/models/concerns/algolia_searchable/**`
- `app/services/search/**`

No OpenSearch/Elasticsearch-first runtime has been confirmed from the inspected Rails files. For the native Go backend, this becomes a target requirement rather than a discovery finding: PostgreSQL remains the source of truth, Elasticsearch is the derived read model, and PostgreSQL search is only a bootstrap/degraded fallback.

## SMTP / Email Runtime

Env vars from `.env_sample` and `Settings::SMTP`:

```text
SMTP_ADDRESS
SMTP_PORT
SMTP_DOMAIN
SMTP_USER_NAME
SMTP_PASSWORD
SMTP_AUTHENTICATION
DEFAULT_EMAIL
```

PoC may run without SMTP, but production user flows should assume SMTP is needed for notifications, password reset, verification, and invitations.

## Edge / Cache Runtime

Relevant env vars:

```text
FASTLY_API_KEY
FASTLY_SERVICE_ID
OPENRESTY_URL
```

For PoC:

```text
SKIP_FASTLY_CONFIG_UPDATE=true
FASTLY_API_KEY unset
FASTLY_SERVICE_ID unset
OPENRESTY_URL unset
```

Cache-bust worker enqueueing still runs in `app_initializer:setup`; verify it does not require a live edge backend in PoC.

## Development-Only Compose Notes

`docker-compose.yml` is development-oriented:

- builds target `development`
- mounts source tree
- runs web via `bundle exec rails server -b 0.0.0.0`
- sidekiq via `bundle exec sidekiq`
- local pgvector Postgres 13
- Redis 7 alpine
- esbuild watch
- browserless Chrome

`container-compose.yml` is also development-oriented and references `quay.io/forem/forem:development` plus local services.

Do not use either file directly as production Kubernetes source of truth; use them only for command/env discovery.

## Kubernetes PoC Process Mapping

### `Deployment/noema-web`

Command:

```bash
bundle exec puma -C config/puma.rb
```

Port:

```text
3000
```

Readiness probe candidates:

- `/` as cheap smoke initially
- later use a tokenized health endpoint if enabled/discovered via `Settings::General.health_check_token`

### `Deployment/noema-worker`

Command:

```bash
bundle exec sidekiq -t 25
```

### `Job/noema-migrate`

Command:

```bash
./release-tasks.sh
```

Clear env:

```text
SKIP_FASTLY_CONFIG_UPDATE=true
STATEMENT_TIMEOUT=4500000
```

### Secrets

Required Kubernetes Secret keys for PoC:

```text
RAILS_MASTER_KEY
FOREM_OWNER_SECRET
DATABASE_URL
REDIS_URL
REDIS_SIDEKIQ_URL
REDIS_SESSIONS_URL
REDIS_RPUSH_URL
SESSION_KEY
```

Optional Secret keys for S3 once storage is ready:

```text
AWS_ID
AWS_SECRET
AWS_BUCKET_NAME
AWS_UPLOAD_REGION
AWS_ENDPOINT_URL       # proposed patch/spike
AWS_FORCE_PATH_STYLE   # proposed patch/spike
```

Optional Secret keys for SMTP:

```text
SMTP_ADDRESS
SMTP_PORT
SMTP_DOMAIN
SMTP_USER_NAME
SMTP_PASSWORD
SMTP_AUTHENTICATION
DEFAULT_EMAIL
```

## Open Runtime Risks

1. **S3-compatible endpoint support is not explicit.** Needs spike or patch before relying on Onidel/object storage.
2. **Release task enqueues cache/data update workers.** Need observe first migration job logs carefully.
3. **Redis URL normalization can mask DNS errors.** Verify real DNS resolution and logs from pod.
4. **Production DB schema search path includes `heroku_ext`.** Existing CNPG may need compatible schema/extension handling.
5. **Image still uses Forem internal paths and user names.** Safe for first boot, but rebrand later.
6. **No SMTP limits user lifecycle flows.** Acceptable only for PoC with an admin bootstrap path.
7. **Legacy Rails search remains Algolia/PostgreSQL-shaped.** Native Noema must not inherit that as the final architecture; add Elasticsearch as a first-class Go backend search module with provider seam, aliases, analyzers, reindex jobs, and PostgreSQL fallback.

## Immediate Next Step

Create the Kubernetes packaging spike using this runtime map:

- `deploy/k8s/base/namespace.yaml`
- `deploy/k8s/base/deployment-web.yaml`
- `deploy/k8s/base/deployment-worker.yaml`
- `deploy/k8s/base/job-migrate.yaml`
- `deploy/k8s/base/service.yaml`
- `deploy/k8s/base/kustomization.yaml`

Render with:

```bash
kubectl kustomize deploy/k8s/base >/tmp/noema-rendered.yaml
```

Do not deploy to the cluster until database/Redis/S3 secret names and namespace ownership are confirmed.
