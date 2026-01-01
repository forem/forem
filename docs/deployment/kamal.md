## Kamal Deployments

Kamal provides a batteries-included way to build the Forem container image, push
it to a registry, and boot the Rails/Sidekiq processes on any SSH-accessible
host. This repo now ships with a pragmatic configuration that assumes:

- You will terminate TLS and serve static files through a separate Nginx proxy.
- Postgres and Redis can run on the same host (via Kamal accessories) or be
  swapped out for managed services by overriding the corresponding env vars.

### Prerequisites

- Docker 24+ and BuildKit enabled locally.
- Kamal `>= 2.8` installed on your workstation (`gem install kamal`).
- A remote host (or set of hosts) with:
  - Docker installed
  - Passwordless SSH access for your deploy user
  - Nginx (or another reverse proxy) listening on ports 80/443
- Access to a container registry (GHCR works out of the box).

### One-time setup

1. Copy `.kamal/secrets.example` to `.kamal/secrets` and replace the placeholder
   references with your secret sources (environment variables, password manager
   helpers, etc). At a minimum you must provide:
   - `KAMAL_REGISTRY_PASSWORD`
   - `RAILS_MASTER_KEY`
   - `POSTGRES_PASSWORD`
   - `DATABASE_URL` (e.g. `postgresql://forem:<password>@postgres:5432/forem_production`)
   - `FOREM_OWNER_SECRET`
   - Optional: `HONEYBADGER_API_KEY`
2. Export the following environment variables before deploying (or store them in
   your shell profile):

   ```
   export KAMAL_WEB_HOSTS=your.host.name
   export KAMAL_REGISTRY_USERNAME=ghcr-username
   export KAMAL_REGISTRY_SERVER=ghcr.io # optional, defaults to ghcr.io
   export APP_DOMAIN=community.example.com
   export APP_PROTOCOL=https://
   ```

   You can also override `KAMAL_IMAGE`, `WEB_CONCURRENCY`, `KAMAL_WEB_PUBLISH`,
   etc. as needed.

3. Log in to your registry (ex. `echo $KAMAL_REGISTRY_PASSWORD | docker login ghcr.io -u "$KAMAL_REGISTRY_USERNAME" --password-stdin`).
4. Provision the remote host with Docker and Nginx. The included
   `docs/deployment/nginx_forem.example.conf` file is a good starting point for
   the proxy layer.

### Deploy flow

```bash
# First time on a new host
kamal setup

# Build/push image, boot containers, and run health checks
kamal deploy

# Run database migrations or other release tasks when needed
kamal app exec --reuse --primary "bundle exec rails db:migrate"
kamal app exec --reuse --primary "./release-tasks.sh"
```

Additional helpers:

- `kamal app logs -r web` – tail Puma logs
- `kamal app logs -r worker` – tail Sidekiq logs
- `kamal accessory ssh postgres` – open a shell inside the Postgres accessory

### Accessory services

The default configuration boots a Postgres 15 container and a Valkey/Redis 8
container on the same host. Persistent volumes (`forem_pg`, `forem_redis`,
`forem_public`, `forem_uploads`, `forem_storage`) are created automatically. If
you prefer managed services, simply point `DATABASE_URL` and `REDIS_URL` at the
managed endpoints and unset the `accessories` entries for the local containers.

### Nginx in front of Kamal

Because we skip Kamal’s built-in Traefik proxy, you are free to run a dedicated
Nginx (or load balancer) in front of the app. The Puma container listens on
`3000` and the provided config publishes that port to the host, so Nginx can
reverse-proxy to `http://127.0.0.1:3000`.

See `docs/deployment/nginx_forem.example.conf` for a reference vhost that:

- Terminates TLS (assuming certificates managed by certbot/lego/etc.)
- Proxies `/` requests to the Kamal-managed Puma container
- Streams uploads and assets without buffering
- Provides a separate `location /cable` block for ActionCable

Enable the site (e.g. symlink into `/etc/nginx/sites-enabled`) and reload
Nginx after each deploy to pick up any config tweaks.

