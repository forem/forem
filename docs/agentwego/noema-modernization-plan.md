# Noema Modernization Implementation Plan

> **For Hermes:** Use `subagent-driven-development` for implementation phases after this plan is accepted; each phase should land as a small PR/branch with verification output.

**Goal:** Transform the Forem fork into **Noema**, an independent self-hosted knowledge community platform for AgentWeGo-scale operations.

**Architecture:** Keep Forem as the upstream compatibility baseline and legacy migration reference, but treat the long-term Noema direction as a parallel native rewrite. The immediate Rails PoC remains useful for learning runtime semantics; the target product should move toward Solito/NativeWind clients, a Go/Gin/GORM backend, native Elasticsearch search, PostgreSQL, Redis, S3-compatible object storage, Kubernetes, and GitOps.

**Tech Stack:** Legacy baseline: Ruby on Rails / Sidekiq / PostgreSQL / Redis / imgproxy / object storage. Native target: Solito / NativeWind / Next.js / React Native Android / React Native Windows spike / Go / Gin / GORM / PostgreSQL / Redis / Elasticsearch / S3-compatible object storage / Kubernetes / GitOps.

---

## Current Baseline

- Upstream: `forem/forem`
- Fork/product: `agentwego/noema`
- Local checkout: `/home/yun/Desktop/noema`
- License: AGPL-3.0; preserve upstream license and attribution.
- Current local clone is shallow; fetch full history before heavy upstream-sync work if needed.
- Existing cluster dependencies intended for reuse:
  - PostgreSQL: CNPG `app-db`
  - Redis: existing standalone Redis on `prod-sg-cache-01`
  - Object storage: S3-compatible endpoint to be prepared/verified before uploads/backups become production requirements

## Target Product Positioning

**Noema** is an open, self-hosted knowledge community platform rebuilt from Forem for modern identity, multilingual search, cloud-native deployment, and large-scale community operations.

The first milestone is not a full rebrand of every string. The first milestone is a deployable, observable Noema PoC that can run in the existing cluster without disturbing database/search/control-plane nodes.

## Deployment Placement Recommendation

### PoC placement

Prefer scheduling Rails web and Sidekiq worker on:

- Primary choice: `prod-sg-db-03`
- Secondary choice: `prod-sg-db-02`

Rationale:

- Avoid `prod-sg-search-01`: existing memory pressure is high.
- Avoid `prod-sg-cache-01`: control-plane taint and existing Redis responsibility.
- Avoid `prod-sg-etcd-01`: stability/resource profile unsuitable for application workloads.
- Avoid `prod-sg-storage-01`: storage-focused, low memory, not ideal for Rails/Sidekiq.
- Avoid overloading the CNPG primary where possible; keep Noema app placement adjustable via node selectors/affinity.

### Initial shape

- `web`: 1 replica
- `worker`: 1 replica
- `migration`: one-shot Job before/with rollout
- `imgproxy`: 1 replica or reused sidecar/service depending on actual Forem runtime needs
- `postgres`: external CNPG database/user/secret
- `redis`: external Redis URL secret
- `uploads`: S3-compatible object storage once bucket/credentials are prepared

## Required User-Provided Inputs Before Production Cutover

These are not required to keep planning, but are required before public production deployment:

1. Domain name, e.g. `noema.agentwego.com`.
2. Whether Noema starts public, private invite-only, or internal-only.
3. S3-compatible bucket details:
   - bucket for uploads
   - optional separate bucket/prefix for backups
   - endpoint
   - region
   - access key / secret key via Kubernetes Secret only
4. SMTP posture:
   - no SMTP for PoC, or
   - SMTP credentials and sender domain for production invitations/password reset/notifications.
5. Identity posture:
   - use Ory Kratos as the native target for identity/session/self-service flow integration,
   - keep local-only DTO/spec seams during M0,
   - do not build a long-lived custom Noema authentication system.
6. Search posture:
   - native Elasticsearch is the target backend search engine,
   - PostgreSQL search may remain as bootstrap/degraded fallback only,
   - verify Chinese analyzer/plugin availability before production indexing.

---

## Phase 0: Repository and Brand Bootstrap

### Task 0.1: Record Noema identity in repository docs

**Objective:** Add a stable Noema project plan and avoid losing the product direction during upstream syncs.

**Files:**

- Create: `docs/agentwego/noema-modernization-plan.md`
- Later modify: `README.md` or `docs/agentwego/README.md`

**Steps:**

1. Create this plan document.
2. Verify `git status --short` only includes intended docs plus any pre-existing ignored/untracked scratch paths.
3. Commit as `docs: add Noema modernization plan`.

**Verification:**

```bash
cd /home/yun/Desktop/noema
git status --short
git log -1 --oneline
```

### Task 0.2: Establish upstream-sync policy

**Objective:** Keep `upstream` fetch-only and make accidental pushes to `forem/forem` impossible.

**Files:**

- Git remote config only

**Steps:**

1. Keep `origin=https://github.com/agentwego/noema.git`.
2. Keep `upstream=https://github.com/forem/forem.git`.
3. Keep `upstream` push URL set to `DISABLED`.

**Verification:**

```bash
git remote -v
# Expect origin fetch/push to agentwego/noema, upstream fetch to forem/forem, upstream push to DISABLED.
```

---

## Phase 1: Cloud-Native Runtime Spike

### Task 1.1: Inventory Forem runtime entrypoints

**Objective:** Identify exact commands/processes needed for web, worker, migrations, and asset/imgproxy flows.

**Files to inspect:**

- `docker-compose.yml`
- `Dockerfile*`
- `Procfile*`
- `.env_sample`
- `selfhost/**` if present
- `config/**` initializers relevant to Redis, database, uploads, and mail

**Expected output:**

Create `docs/agentwego/runtime-inventory.md` with:

- web command
- worker command
- migration command
- required environment variables
- optional environment variables
- current gaps for S3-compatible endpoint/path-style

**Verification:**

```bash
grep -nE 'DATABASE_URL|REDIS_URL|AWS_|SMTP|ALGOLIA' .env_sample
test -s docs/agentwego/runtime-inventory.md
```

### Task 1.2: Build a minimal Kubernetes packaging spike

**Objective:** Produce a deployable but non-production Noema manifest set with external PostgreSQL/Redis.

**Files:**

- Create: `deploy/k8s/base/namespace.yaml`
- Create: `deploy/k8s/base/deployment-web.yaml`
- Create: `deploy/k8s/base/deployment-worker.yaml`
- Create: `deploy/k8s/base/job-migrate.yaml`
- Create: `deploy/k8s/base/service.yaml`
- Create: `deploy/k8s/base/ingress.yaml` or Gateway API equivalent if the infra repo prefers it
- Create: `deploy/k8s/base/kustomization.yaml`

**Important constraints:**

- Do not commit real secrets.
- Use placeholder Secret names only.
- Add node selector/affinity values that can be overridden by GitOps.
- Single replica only for PoC.

**Verification:**

```bash
kubectl kustomize deploy/k8s/base >/tmp/noema-rendered.yaml
grep -nE 'kind: Deployment|kind: Job|kind: Service|noema' /tmp/noema-rendered.yaml
```

### Task 1.3: Prepare external database bootstrap plan

**Objective:** Define how Noema gets a database/user in existing CNPG without embedding credentials in Git.

**Files:**

- Create: `docs/agentwego/database-bootstrap.md`

**Expected content:**

- target CNPG cluster
- database name: `noema`
- user name: `noema`
- secret handoff shape
- migration execution path
- rollback strategy: keep DB, scale app to zero, do not drop data during early PoC

**Verification:**

```bash
test -s docs/agentwego/database-bootstrap.md
grep -nE 'noema|CNPG|rollback' docs/agentwego/database-bootstrap.md
```

---

## Phase 2: Object Storage and Media

### Task 2.1: Verify Forem S3-compatible support from code

**Objective:** Determine whether Noema can use the target S3-compatible endpoint without code changes.

**Files to inspect:**

- `.env_sample`
- upload/storage initializers
- uploader models/services
- any `fog`, `carrierwave`, ActiveStorage, or AWS SDK configuration

**Expected output:**

Create `docs/agentwego/s3-compatibility.md` with:

- supported env vars
- whether endpoint override exists
- whether path-style addressing exists
- whether upload and backup buckets can differ
- exact patch needed if endpoint/path-style is missing

**Verification:**

```bash
grep -RInE 'AWS_|S3|s3|endpoint|path_style|force_path' app config lib .env_sample | head -100
```

### Task 2.2: Patch S3-compatible endpoint support if needed

**Objective:** Add explicit support for S3-compatible endpoints using env vars, while preserving AWS S3 default behavior.

**Candidate env vars:**

- `AWS_UPLOAD_REGION`
- `AWS_BUCKET_NAME`
- `AWS_ENDPOINT_URL`
- `AWS_FORCE_PATH_STYLE`

**Testing:**

- Add unit/regression tests around storage config object construction.
- Do not test with real credentials in CI.
- Add a local manual verification recipe using a dummy MinIO or provided endpoint.

---

## Phase 3: Native Elasticsearch Search Modernization

### Task 3.1: Make Elasticsearch the target search posture

**Objective:** Treat Elasticsearch as a first-class Noema backend module instead of an optional late plugin.

**Recommended sequence:**

1. PoC/legacy learning: inspect upstream Forem search and Algolia/PostgreSQL assumptions.
2. Native backend: create an `internal/search` provider seam before implementing article/comment handlers deeply.
3. Add Elasticsearch provider with versioned indexes, aliases, bulk indexing, and Chinese analyzer support.
4. Keep PostgreSQL search only as bootstrap/degraded fallback, selected by `SEARCH_PROVIDER=postgres`.
5. Add full reindex, incremental indexing, dead-letter logging, and operational docs.

**Native backend files to create:**

- `services/api/internal/search/index.go`
- `services/api/internal/search/documents.go`
- `services/api/internal/search/elastic/client.go`
- `services/api/internal/search/elastic/mappings.go`
- `services/api/internal/search/elastic/indexer.go`
- `services/api/internal/search/elastic/query.go`
- `services/api/internal/search/elastic/aliases.go`
- `services/api/internal/search/fallback/postgres.go`

**Legacy files to inspect:**

- `app/controllers/search_controller.rb`
- `app/services/search/**`
- `app/models/concerns/algolia_searchable/**`
- `config/initializers/algoliasearch.rb`
- `Gemfile`

**Verification for discovery:**

```bash
grep -RInE 'Search::|Algolia|pg_search|ransack|elasticsearch|opensearch' app config Gemfile
```

### Task 3.2: Design multilingual search provider boundary

**Objective:** Make Chinese search and mixed-language discovery a native backend read model with explicit operational controls.

**Expected docs:**

- `docs/agentwego/search-architecture.md`
- `docs/agentwego/noema-native-rewrite-strategy.md`

**Must include:**

- PostgreSQL as source of truth and Elasticsearch as derived read model
- article/comment/user/tag searchable fields
- versioned index naming and read/write aliases
- analyzer choice for Chinese and mixed Chinese/English content
- reindex trigger, debounce, bulk indexing, and dead-letter strategy
- degraded fallback to PostgreSQL search
- operational metrics and alerting

---

## Phase 4: Identity and Authentication

### Task 4.1: Keep local login for first boot

**Objective:** Minimize boot blockers. Do not require Discord/OIDC before the first Noema deployment works.

**Verification:**

- local admin can sign in
- password reset limitations are documented if SMTP is disabled

### Task 4.2: Evaluate Discord/OIDC options

**Objective:** Converge identity/session work on Ory Kratos-native boundaries while preserving local verification and an admin recovery posture.

**Options:**

1. Ory Kratos identity traits, sessions, and self-service flows as the target integration boundary.
2. Optional OIDC/Hydra or external identity providers behind Kratos-compatible flows.
3. Local-only DTO/spec seams for early migration slices; no live Kratos client until explicitly planned and verified.

**Expected doc:**

- `docs/agentwego/identity-options.md`

**Must include:**

- admin bootstrap path if external identity breaks
- account linking semantics
- email verification posture
- invite-only posture
- rollback path to local login

---

## Phase 5: Product Rebrand and UI Direction

### Task 5.1: Separate product branding from upstream sync

**Objective:** Rebrand user-facing Noema surfaces without making future upstream merges impossible.

**Approach:**

- Start with config-driven site name and docs.
- Avoid mass replacing every `Forem` string in code until runtime and tests are stable.
- Add Noema-specific theme/assets behind configuration.
- Keep upstream attribution and license files intact.

**Verification:**

```bash
git diff --stat
grep -RIn 'Noema' README.md docs config app 2>/dev/null || true
```

### Task 5.2: Define Noema information architecture

**Objective:** Make the redesign coherent before UI rewrites.

**Expected doc:**

- `docs/agentwego/product-architecture.md`

**Must include:**

- content types
- community/group model
- moderation model
- search/discovery model
- identity model
- admin model
- what remains compatible with Forem

---

## Phase 6: Production Readiness

### Task 6.1: Observability and operations

**Objective:** Ensure Noema can be diagnosed through real user paths, not just health checks.

**Required:**

- fresh application logs
- migration logs
- Sidekiq queue visibility
- Redis connectivity check
- database connectivity check
- upload test
- real browser login/post/comment path

### Task 6.2: Backup and rollback

**Objective:** Define a reversible production cutover.

**Required:**

- DB backup / restore path
- object storage backup policy
- app rollback to previous image
- migration rollback policy
- scale-to-zero emergency path
- admin account recovery path

---

## First Execution Branches

Recommended branch order:

1. `docs/noema-modernization-plan`
2. `spike/runtime-inventory`
3. `spike/k8s-minimal`
4. `spike/s3-compatibility`
5. `spike/search-boundary`
6. `spike/identity-options`

Each branch should contain one coherent artifact and verification output. Avoid combining branding, K8s, S3, identity, and search code in one mega-commit.

## Open Decisions

- Final public domain for Noema.
- Whether repo remains public fork or becomes private during deep rewrite.
- S3 bucket/endpoint/region/credentials.
- SMTP provider or no-SMTP PoC.
- Exact Ory Kratos deployment/runtime posture, identity schema, self-service UI handoff, and admin recovery bootstrap.
- Whether Chinese search is a first production requirement or a post-PoC phase.

## Immediate Next Step

After this plan lands, run the runtime inventory task and produce `docs/agentwego/runtime-inventory.md`. That gives the exact process/env list needed before writing Kubernetes manifests.
