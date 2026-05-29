# Forem Deployment Guide using Kamal 2 (Beta)

This guide provides instructions, architectural details, and platform-specific gotchas for hosting Forem using [Kamal 2](https://kamal-deploy.org/).

---

## Architecture Overview

When deploying Forem with Kamal 2, the application runs inside Docker containers on target servers. 

```mermaid
flowchart TD
    Client[Client Traffic] -->|HTTPS 443| KP[Kamal Proxy]
    KP -->|Port 3000| Web[Web App Container]
    Web -->|Internal Port 5432| DB[(PostgreSQL + pgvector)]
    Web -->|Internal Port 6379| Redis[(Redis Caching & Sidekiq)]
    Sidekiq[Sidekiq Worker Container] -->|Internal Port 5432| DB
    Sidekiq -->|Internal Port 6379| Redis
```

- **Kamal Proxy**: Kamal 2 automatically provisions and manages Kamal Proxy, routing external HTTP/HTTPS traffic to the Forem app container running on port `3000`.
- **Sidekiq Worker**: A dedicated background processing role (`job`) runs Sidekiq on the specified target servers.
- **Accessories**: PostgreSQL and Redis run as standalone Docker containers managed by Kamal on the designated host(s).

---

## 1. Secrets Management

Kamal 2 manages secrets via the `.kamal/secrets` file. This file reads from your local system's environment variables or password managers and safely feeds them into Kamal without hardcoding plain text.

Before running any Kamal command, make sure to define the following environment variables on your local machine (or CI/CD runner):
```bash
# Server and Accessory IPs (Evaluated in config/deploy.yml ERB)
export KAMAL_WEB_IP="192.168.0.1"
export KAMAL_JOB_IP="192.168.0.1"
export KAMAL_DB_IP="192.168.0.1"
export KAMAL_REDIS_IP="192.168.0.1"

# Secrets and credentials
export KAMAL_REGISTRY_PASSWORD="your-registry-token"
export RAILS_MASTER_KEY="your-rails-master-key"
export DATABASE_URL="postgresql://postgres:postgres_secure_password@forem-postgres:5432/forem_production"
export POSTGRES_PASSWORD="postgres_secure_password"
```

---

## 2. Cloud Provider Guides & Gotchas

### 🚀 DigitalOcean
DigitalOcean is highly compatible with Kamal due to its simple droplet infrastructure.

*   **Registry**: DigitalOcean Container Registry (DOCR) or GitHub Container Registry (GHCR) work seamlessly. If using DOCR, your registry server is `registry.digitalocean.com`.
*   **Networking**: Always use droplets in the same VPC. Bind your postgres and redis accessories to the private network interface (e.g., `10.x.x.x`) to keep database ports closed to the public internet.
*   **Gotcha (IP Pools)**: If you use a DigitalOcean Load Balancer or Floating IP, ensure the load balancer terminates SSL, or let Kamal Proxy handle SSL termination directly on the droplet if pointing DNS directly to it.

### 🇩🇪 Hetzner Cloud
Hetzner is a highly cost-effective option for bare metal and cloud servers.

*   **Setup**: Use Hetzner's private networks (vSwitch) to connect your app droplets to database hosts.
*   **Firewalls**: Configure Hetzner Cloud Firewalls to only allow inbound traffic on port `80` and `443` (for Kamal Proxy) and port `22` (for SSH/deployments). Block public access to `5432` and `6379`.
*   **Gotcha (Docker MTU)**: On some Hetzner networks, the default MTU can cause Docker build or push commands to hang. If you run into network timeout issues, configure Docker's MTU to `1400` or `1450` in `/etc/docker/daemon.json`.

### 💻 Amazon Web Services (AWS EC2 / Lightsail)
AWS provides robust scaling options, but requires careful security group mapping.

*   **IAM & ECR**: If hosting your images on AWS Elastic Container Registry (ECR), your registry server will resemble `aws_account_id.dkr.ecr.region.amazonaws.com`. You must set up local AWS CLI credentials so Kamal can authenticate.
*   **Security Groups**:
    *   **Web SG**: Inbound `80`/`443` from anywhere (or ALB). Inbound `22` from your deployment IP.
    *   **DB SG**: Inbound `5432` only from the Web Security Group.
*   **Managed Services (RDS & ElastiCache)**:
    *   While you can run postgres/redis as local accessories, for AWS we highly recommend using **Amazon RDS (PostgreSQL)** and **Amazon ElastiCache (Redis)**.
    *   If using RDS, remove the `postgres` accessory block from `config/deploy.yml` and provide the RDS host URL in `DATABASE_URL`.
    *   If using RDS, ensure you manually install the `pgvector` extension in your RDS instance (`CREATE EXTENSION IF NOT EXISTS vector;`) before running migrations.

### ☁️ Google Cloud Platform (GCP Compute Engine)
GCP is suitable for containerized ecosystems.

*   **Registry**: Use GCP Artifact Registry (`region-docker.pkg.dev`). Use a service account key as your `KAMAL_REGISTRY_PASSWORD`.
*   **Managed Services**: For GCP, consider **Cloud SQL (PostgreSQL)** and **Cloud Memorystore (Redis)**.
*   **Gotcha (Service Accounts)**: Make sure the VM service account has the `Artifact Registry Reader` role to pull images.

---

## 3. Forem-Specific Deployment Gotchas

### 🔴 The pgvector Database Requirement
Forem requires `pgvector` (version `0.8.0` or higher) to support HNSW vector search indexing.
*   **Standard Postgres images will fail** to run Forem's database migrations.
*   Ensure the database image used is `pgvector/pgvector:pg13` (as pre-configured in `config/deploy.yml`).
*   If using a managed database (like AWS RDS or GCP Cloud SQL), verify that the engine version supports `pgvector` and that the extension is active.

### 📦 Asset Bridging (Zero Downtime)
Forem utilizes fingerprinted assets (Sprockets/esbuild).
*   During a rolling deploy, users might request older fingerprinted assets that exist on the old container but not the new one.
*   To prevent `404 Not Found` errors, the configuration defines:
    ```yaml
    asset_path: /opt/apps/forem/public/assets
    ```
    Kamal automatically copies assets from the old container to the shared host path, merging them with the new assets so both sets remain available.

### 🔒 SSL & Cloudflare
Kamal Proxy automatically requests Let's Encrypt SSL certificates if `proxy.ssl` is set to `true`.
*   **If using Cloudflare**: Set your SSL/TLS encryption mode to **Full** (or **Full (strict)**) in the Cloudflare dashboard.
*   Using "Flexible" mode will cause redirect loops because Cloudflare communicates with Kamal Proxy over HTTP, while the app enforces HTTPS redirection.

### ⚙️ Database Connection Limits & Sidekiq
In Forem, Sidekiq runs concurrently with multiple threads.
*   By default, the Sidekiq db pool is configured dynamically as `sidekiq_concurrency + 5` to prevent connection starvation.
*   Make sure your PostgreSQL accessory (`max_connections` setting) or managed database can handle the combined connection pool:
    $$\text{Total Connections} = (\text{Web Containers} \times \text{Puma Pool}) + (\text{Sidekiq Containers} \times (\text{Sidekiq Concurrency} + 5))$$

---

## 4. Useful Deployment Commands

Always prefix Kamal commands with `bundle exec` if you installed the gem via Bundler:

```bash
# Verify config and environment secrets resolution
bundle exec kamal config

# Run initial setup (installs Docker, boots accessories, builds/pushes image, boots app)
bundle exec kamal setup

# Deploy a rolling update (builds, pushes, and switches containers)
bundle exec kamal deploy

# Roll back to the previous release
bundle exec kamal rollback

# View application logs
bundle exec kamal app logs -f

# SSH into the server and open a Rails console
bundle exec kamal app exec -i --reuse "bin/rails console"
```
