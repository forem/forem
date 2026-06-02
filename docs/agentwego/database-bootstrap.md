# Noema Database Bootstrap Plan

> **For Hermes:** This document is a handoff and rollback plan only. Do not create users, databases, or Secrets until the operator confirms namespace ownership, maintenance window, and rollback path.

## Goal

Prepare a low-risk PostgreSQL bootstrap path for the Noema Rails PoC and future native Noema backend while keeping credentials out of git.

## Target Runtime

| Item | Value |
| --- | --- |
| Kubernetes namespace | `noema` |
| Application database | `noema` |
| Application user | `noema` |
| Provider | existing CNPG `app-db` cluster |
| Runtime Secret | `noema-runtime-secrets` |
| Primary env var | `DATABASE_URL` |
| Optional override | `NEW_DATABASE_URL` |

## Required Secret Shape

The Kubernetes Secret must be created by GitOps secret tooling or manual sealed/external secret handoff, not committed in plaintext.

Required keys for database and Rails boot:

```text
RAILS_MASTER_KEY
FOREM_OWNER_SECRET
DATABASE_URL
SESSION_KEY
```

`DATABASE_URL` shape:

```text
postgres://noema:<password>@<cnpg-rw-service>:5432/noema?sslmode=require
```

If the in-cluster CNPG service does not use TLS for pod-local traffic, document the chosen `sslmode` before creating the Secret.

## Bootstrap Sequence

1. Confirm target CNPG cluster and service name for write traffic.
2. Confirm whether `noema` database/user already exists.
3. Generate a unique password through the approved secret manager.
4. Create role and database using the CNPG/operator-approved path.
5. Grant ownership and privileges only for the `noema` database.
6. Create or sync `noema-runtime-secrets` with `DATABASE_URL` and other Rails runtime keys.
7. Run the migration Job only after Redis URLs are also present.
8. Capture migration logs and keep them attached to the deployment record.

## SQL Sketch

Use only as a conceptual sketch; prefer the CNPG-managed mechanism in the actual cluster.

```sql
CREATE ROLE noema LOGIN PASSWORD '<generated-password>';
CREATE DATABASE noema OWNER noema;
GRANT ALL PRIVILEGES ON DATABASE noema TO noema;
```

## Rails Migration Path

The render-only Kubernetes spike defines `Job/noema-migrate` running:

```bash
./release-tasks.sh
```

`release-tasks.sh` invokes:

```bash
STATEMENT_TIMEOUT=4500000 bundle exec rails app_initializer:setup
bundle exec rake fastly:update_configs
bundle exec rails runner "puts 'app load success'"
```

For PoC, keep:

```text
SKIP_FASTLY_CONFIG_UPDATE=true
STATEMENT_TIMEOUT=4500000
```

## Required Preflight Checks Before Running Migration

```bash
kubectl -n noema get secret noema-runtime-secrets
kubectl -n noema get configmap noema-runtime-config
kubectl -n noema run noema-db-dns-check --rm -it --restart=Never --image=postgres:16 -- pg_isready -d "$DATABASE_URL"
```

Use the real Secret/tooling path to inject `DATABASE_URL`; do not paste credentials into chat or git.

## Rollback Strategy

Early PoC rollback is non-destructive:

1. Scale app workloads to zero or delete the PoC namespace resources.
2. Keep the `noema` database intact for forensic inspection.
3. Do not drop the database during early PoC unless explicitly requested after backup.
4. Keep migration Job logs and application logs.
5. If a bad app image was rolled out, roll back only the Deployment image or delete the Deployment; do not mutate data.

Emergency scale-to-zero commands, after confirming namespace:

```bash
kubectl -n noema scale deployment/noema-web --replicas=0
kubectl -n noema scale deployment/noema-worker --replicas=0
```

## Production Cutover Blockers

- Confirm namespace ownership and GitOps repo destination.
- Confirm exact CNPG service and credential generation mechanism.
- Confirm Redis DB split and URLs.
- Confirm S3-compatible storage support or patch.
- Confirm SMTP posture for lifecycle emails.
- Confirm admin bootstrap path.
- Confirm backup/restore process before public traffic.
