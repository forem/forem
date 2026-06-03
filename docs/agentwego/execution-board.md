# Noema Super Engineering Execution Board

> **For Hermes:** This board is the operational control plane for the Noema super-engineering effort. Before implementing any slice, select the phase, cite inventory CSV rows, define gates, and record real verification output. Do not deploy or touch production data without an explicit maintenance window and rollback path.

## Current Charter

Noema is a Forem-derived but Noema-native knowledge community platform. The current Rails/Preact repository is a legacy reference, runtime PoC, and migration source. The long-term product is a Solito/NativeWind client suite backed by a Go/Gin/GORM API, PostgreSQL source of truth, Redis coordination, Elasticsearch derived search indexes, S3-compatible object storage, Kubernetes, and GitOps.

## Ground Rules

1. Treat this as a rewrite, not a line-by-line port.
2. Keep Forem/Rails semantics as reference input; do not copy the Rails global shell.
3. Do not replay every Rails migration into the native schema; design clean Noema tables plus explicit importers.
4. Elasticsearch is a first-class backend read model from the start; PostgreSQL search is only bootstrap/degraded fallback.
5. Every implementation branch must cite rows from `docs/agentwego/noema-file-migration-inventory.csv` and check adjacent edges in `docs/agentwego/noema-file-dependency-edges.csv`.
6. Every branch must land one coherent artifact with verification output.
7. No real secrets in git. Use placeholder Secret names and document handoff shape only.
8. No production/cluster cutover without rollback path, logs, and real user-path verification.

## Baseline Artifacts

| Artifact | Role |
| --- | --- |
| `docs/agentwego/noema-modernization-plan.md` | Immediate modernization phases and PoC runtime direction. |
| `docs/agentwego/runtime-inventory.md` | Rails/Forem-derived process/env/deployment inventory. |
| `docs/agentwego/noema-native-rewrite-strategy.md` | Long-term native stack strategy and Elasticsearch requirements. |
| `docs/agentwego/noema-deep-dependency-migration-plan.md` | File-by-file migration control document. |
| `docs/agentwego/noema-file-migration-inventory.csv` | Per-file migration inventory. |
| `docs/agentwego/noema-file-dependency-edges.csv` | File dependency edges; use before declaring a slice isolated. |
| `docs/agentwego/noema-domain-dependency-summary.csv` | Domain dependency graph. |
| `docs/agentwego/noema-controller-map.csv` | Controller filters/service calls for route/API planning. |
| `docs/agentwego/noema-model-dependency-map.csv` | Rails model associations/callbacks/scopes for schema/import planning. |
| `docs/agentwego/noema-worker-map.csv` | Sidekiq worker queues/service calls for native jobs planning. |
| `docs/agentwego/native-stack-skeleton.md` | First native Go API skeleton, config/search seams, and local verification. |
| `docs/agentwego/local-verification-entrypoints.md` | Taskfile-based local verification commands and outputs. |
| `docs/agentwego/search-index-spec.md` | Local-only Elasticsearch index spec builder, analyzer posture, and verification. |

## Active Milestone M0: Baseline and Cloud-Native PoC Packaging

**Goal:** Freeze dependency baseline, create a safe Kubernetes render-only PoC package, and document DB/S3/search bootstrap decisions before any cluster deployment.

**Non-goals:**

- No production deployment.
- No real Kubernetes Secret manifests.
- No Rails mass rebrand.
- No full native Go backend implementation or external dependency integration yet.
- No database creation or destructive schema changes.

## Gates

### Gate G0 — Baseline Integrity

**Entry:** dependency baseline files exist under `docs/agentwego/`.

**Checks:**

```bash
python -c "import csv; files=list(csv.DictReader(open('docs/agentwego/noema-file-migration-inventory.csv'))); assert len(files)==5900; assert any(r['file']=='app/models/article.rb' for r in files); assert any(r['file']=='app/controllers/search_controller.rb' for r in files); assert any(r['file']=='config/routes.rb' for r in files); print('inventory ok', len(files))"
test -s docs/agentwego/noema-file-dependency-edges.csv
test -s docs/agentwego/noema-domain-dependency-summary.csv
test -s docs/agentwego/noema-model-dependency-map.csv
test -s docs/agentwego/noema-controller-map.csv
test -s docs/agentwego/noema-worker-map.csv
```

**Failure behavior:** stop implementation and regenerate/fix inventory before using it for task selection.

### Gate G1 — Render-Only Kubernetes Packaging

**Entry:** `deploy/k8s/base/` manifests exist with placeholder Secret references.

**Checks:**

```bash
kubectl kustomize deploy/k8s/base >/tmp/noema-rendered.yaml
grep -nE 'kind: Namespace|kind: Deployment|kind: Job|kind: Service|noema' /tmp/noema-rendered.yaml
```

**Failure behavior:** fix manifests only. Do not deploy.

### Gate G2 — External Dependency Handoff

**Entry:** database, Redis, S3, SMTP, and search posture docs exist.

**Checks:**

```bash
test -s docs/agentwego/database-bootstrap.md
test -s docs/agentwego/s3-compatibility.md
test -s docs/agentwego/search-architecture.md
grep -nE 'rollback|CNPG|noema|Secret' docs/agentwego/database-bootstrap.md
grep -nE 'AWS_ENDPOINT_URL|AWS_FORCE_PATH_STYLE|S3-compatible' docs/agentwego/s3-compatibility.md
grep -nE 'Elasticsearch|alias|analyzer|fallback|reindex' docs/agentwego/search-architecture.md
```

**Failure behavior:** keep work in planning branch; no cluster or production action.

### Gate G3 — Production Action Escalation

**Entry:** any action would create DB/user, write real Secret, deploy workload, point ingress/domain, or migrate data.

**Required before action:**

- maintenance window or explicit PoC approval;
- exact target namespace and cluster;
- DB/Redis/S3 credential source;
- rollback path;
- fresh logs and real user-path verification plan.

**Failure behavior:** ask for missing production inputs; do not proceed by default.

## Branch Sequence

1. `docs/noema-modernization-plan` — current branch; docs baseline and PoC planning.
2. `spike/k8s-minimal` — render-only Kubernetes base manifests.
3. `spike/s3-compatibility` — prove or patch S3-compatible endpoint support.
4. `spike/search-boundary` — search architecture doc and native provider seam design.
5. `spike/native-stack-skeleton` — Go API skeleton only after G0-G2 pass; first local-only skeleton now landed on current branch.

## Task Register

| ID | Status | Phase | Artifact | Inventory Coverage | Verification |
| --- | --- | --- | --- | --- | --- |
| M0-T1 | done | P0 | dependency baseline committed | full CSV baseline | `git log -1 --oneline` |
| M0-T2 | done | P0 | `docs/agentwego/execution-board.md` | planning control | `test -s` + grep gates |
| M0-T3 | done | P0 | `deploy/k8s/base/*` | runtime-config/deploy | `kubectl kustomize` render |
| M0-T4 | done | P0 | `docs/agentwego/database-bootstrap.md` | runtime-config/legacy-schema | grep rollback/CNPG/Secret |
| M0-T5 | done | P0/P2 | `docs/agentwego/s3-compatibility.md`, `config/initializers/carrierwave.rb`, `app/services/agent_sessions/s3_storage.rb`, `.env_sample`, `deploy/k8s/base/configmap.yaml`, `.mise.toml` | `config/initializers/carrierwave.rb`, upload/media files, agent session raw files, local Ruby toolchain | config specs + kustomize + grep S3 vars and patch decision; local Ruby 3.3.0 validation now reproducible via mise |
| M0-T6 | done | P1 | `docs/agentwego/search-architecture.md` | search/controller/model rows | grep ES alias/analyzer/reindex/fallback |
| M0-T7 | done | P1 | `go.mod`, `services/api/**`, `docs/agentwego/native-stack-skeleton.md` | `config/routes.rb`, `config/routes/api.rb`, API health controller, runtime config, search provider rows | TDD RED observed, `go test ./services/api/...`, local `/healthz` smoke on port 19091 |
| M0-T8 | done | P0/P1 | `Taskfile.yml`, `scripts/noema_api_smoke.py`, `docs/agentwego/local-verification-entrypoints.md` | control-plane docs, render-only K8s, native API skeleton | `task --list`, `task verify:local`, stale smoke process check |
| M0-T9 | done | P1 | `services/api/internal/search/elastic/**`, `docs/agentwego/search-index-spec.md` | search provider/index rows | TDD RED observed, `go test ./services/api/internal/search/elastic`, `task verify:local`, no external cluster access |
| M0-T10 | done | P1 | `services/api/internal/search/elastic/**`, `docs/agentwego/search-index-spec.md` | `app/services/search/{article,comment,user,tag}.rb`, legacy Algolia worker rows | TDD RED observed for missing all-family functions, `go test ./services/api/internal/search/elastic`, `task verify:local`, no external cluster access |
| M0-T11 | done | P1 | `services/api/internal/search/elastic/manifest.go`, `services/api/cmd/search-manifest/**`, `Taskfile.yml`, `docs/agentwego/search-index-spec.md` | search provider/index rows, future GitOps/bootstrap review seam | TDD RED observed for missing `BuildManifest`/`ManifestJSON`/CLI `run`, `go test ./services/api/cmd/search-manifest ./services/api/internal/search/elastic`, `task search:manifest`, `task verify:local`, no external cluster access |
| M0-T12 | done | P1 | `services/api/internal/search/elastic/manifest.go`, `services/api/internal/search/elastic/mappings_test.go`, `Taskfile.yml`, `docs/agentwego/search-index-spec.md` | search provider/index rows, manifest drift guard | TDD RED observed for missing `ValidateManifest`, `go test ./services/api/internal/search/elastic ./services/api/cmd/search-manifest`, `go test ./services/api/...`, `task verify:local`, no external cluster access |
| M0-T13 | done | P1 | `services/api/internal/search/elastic/bootstrap_plan.go`, `services/api/cmd/search-bootstrap-plan/**`, `Taskfile.yml`, `docs/agentwego/search-index-spec.md` | search provider/index rows, alias/reindex planning seam | TDD RED observed for missing `WriteAlias`/`BuildBootstrapPlan`/`BootstrapPlanJSON`/CLI `run`, `go test ./services/api/internal/search/elastic ./services/api/cmd/search-bootstrap-plan`, `task search:bootstrap-plan`, `task verify:local`, no external cluster access |
| M0-T14 | done | P1 | `services/api/internal/search/fallback/postgres.go`, `services/api/internal/search/provider.go`, `services/api/cmd/api/main.go`, `docs/agentwego/search-architecture.md` | PostgreSQL degraded fallback rows, search provider seam | TDD RED observed for missing fallback package/provider selector, `go test ./services/api/internal/search ./services/api/internal/search/fallback`, `go test ./services/api/...`, `task api:smoke`, `task verify:local`, no DB/Elasticsearch/Secret access |
| M0-T15 | done | P1 | `services/api/internal/search/elastic/rollback_plan.go`, `services/api/cmd/search-rollback-plan/**`, `Taskfile.yml`, `docs/agentwego/search-index-spec.md` | search bootstrap rollback/recovery seam | TDD RED observed for missing `BuildRollbackPlan`/`RollbackPlanJSON`/CLI `run`, `go test ./services/api/internal/search/elastic ./services/api/cmd/search-rollback-plan`, `task search:rollback-plan`, `task verify:local`, no external cluster access or delete/mutation |
| M0-T16 | done | P1 | `services/api/internal/search/index.go`, `services/api/internal/search/noop.go`, `services/api/internal/search/fallback/postgres.go`, `docs/agentwego/search-architecture.md` | search provider request contract | TDD RED observed for missing `NormalizeSearchRequest`/limit constants/result echo fields, `go test ./services/api/internal/search ./services/api/internal/search/fallback`, `go test ./services/api/...`, `task verify:local`, no DB/Elasticsearch/Secret access |
| M0-T17 | done | P1 | `services/api/internal/http/router.go`, `services/api/internal/http/router_test.go`, `scripts/noema_api_smoke.py`, `docs/agentwego/search-architecture.md` | native HTTP search route contract | TDD RED observed for missing `/search` route and lowercase JSON contract, `go test ./services/api/internal/http`, `go test ./services/api/...`, `task api:smoke`, `task verify:local`, no DB/Elasticsearch/Secret access |
| M0-T18 | done | P1 | `services/api/internal/http/router.go`, `services/api/internal/http/router_test.go`, `docs/agentwego/search-architecture.md` | native HTTP search error contract | TDD RED observed for non-JSON unsupported-method response; provider failure returns stable `503` JSON without backend detail, `go test ./services/api/internal/http`, `task verify:local`, no DB/Elasticsearch/Secret access |
| M0-T19 | done | P1 | `services/api/internal/search/index.go`, `services/api/internal/search/noop.go`, `services/api/internal/search/fallback/postgres.go`, `services/api/internal/http/router.go`, `docs/agentwego/search-architecture.md` | actual provider identity contract | TDD RED observed for `/healthz` echoing config instead of injected provider; provider seam now exposes `Name()`, `go test ./services/api/internal/http ./services/api/internal/search ./services/api/internal/search/fallback`, `task verify:local`, no DB/Elasticsearch/Secret access |
| M0-T20 | done | P1 | `scripts/noema_api_smoke.py`, `docs/agentwego/local-verification-entrypoints.md` | real local smoke covers search error paths | `task api:smoke` now verifies `/search` success plus `400 {"error":"invalid limit"}` and `405 {"error":"method not allowed"}` against a real localhost API process; no DB/Elasticsearch/Secret access |
| M0-T21 | done | P1 | `services/api/cmd/api/main.go`, `services/api/cmd/api/main_test.go`, `scripts/noema_api_smoke.py`, `docs/agentwego/search-architecture.md` | unknown provider local fallback smoke | TDD RED observed for missing `buildSearchProvider`; API now falls back to noop with warning when configured provider is unavailable, and `task api:smoke` verifies postgres and unknown-provider/noop runtime paths on local ports; no DB/Elasticsearch/Secret access |
| M0-T22 | done | P1 | `services/api/cmd/api/main.go`, `services/api/cmd/api/main_test.go`, `docs/agentwego/search-architecture.md` | provider fallback safety boundary | TDD RED observed for `buildSearchProvider` lacking error return; unavailable providers now fall back only in local/test envs and fail fast outside local envs, `go test ./services/api/cmd/api`, `task api:smoke`; no DB/Elasticsearch/Secret access |
| M0-T23 | done | P1 | `services/api/internal/http/router.go`, `services/api/internal/http/router_test.go`, `scripts/noema_api_smoke.py`, `docs/agentwego/search-architecture.md` | HTTP search empty-query guard | TDD RED observed for blank `q` returning `200`; `/search` now rejects missing/blank query with `400 {"error":"missing query"}` and smoke verifies both postgres and noop runtime paths; no DB/Elasticsearch/Secret access |
| M0-T24 | done | P1 | `services/api/internal/http/router.go`, `services/api/internal/http/router_test.go`, `scripts/noema_api_smoke.py`, `docs/agentwego/search-architecture.md` | HTTP unknown-route JSON contract | TDD RED observed for unknown route returning framework plaintext 404; unknown API routes now return stable `404 {"error":"not found"}` JSON and smoke verifies both postgres and noop runtime paths; no DB/Elasticsearch/Secret access |
| M0-T25 | done | P1 | `services/api/internal/http/router.go`, `services/api/internal/http/router_test.go`, `scripts/noema_api_smoke.py`, `docs/agentwego/search-architecture.md` | HTTP health method JSON contract | TDD RED observed for `POST /healthz` returning JSON 404 via catch-all; `/healthz` now owns unsupported-method handling and returns stable `405 {"error":"method not allowed"}` JSON, with smoke coverage for both runtime paths; no DB/Elasticsearch/Secret access |
| M0-T26 | done | P1 | `services/api/internal/config/config.go`, `services/api/internal/config/config_test.go`, `.env_sample`, `docs/agentwego/search-architecture.md` | native search runtime config seam | TDD RED observed for missing `SearchConfig.BulkSize`/`RequestTimeout`; native config now reads non-secret `ELASTICSEARCH_BULK_SIZE` and `ELASTICSEARCH_REQUEST_TIMEOUT` defaults/overrides for local planning without reading credentials or contacting Elasticsearch; `go test ./services/api/internal/config`, `go test ./services/api/...`, and `task verify:local` passed |
| M0-T27 | done | P1 | `services/api/internal/search/noop.go`, `services/api/internal/search/search_test.go`, `docs/agentwego/search-architecture.md` | noop provider mutation safety boundary | TDD RED observed for missing `ErrNoopReadOnly`; noop remains read-only search bootstrap but all indexing mutation methods now return explicit read-only errors instead of silently accepting writes; `go test ./services/api/internal/search`, `go test ./services/api/...`, and `task verify:local` passed |
| M0-T28 | done | P1 | `services/api/internal/persistence/**`, `services/api/internal/config/config.go`, `Taskfile.yml`, `docs/agentwego/native-stack-skeleton.md` | `app/models/article.rb`, `app/models/user.rb`, article/user edge rows | TDD RED observed for missing `DatabaseConfig` and missing persistence package; native Article/User GORM repository now persists users/articles against a disposable local PostgreSQL DB with author integrity; `GOFLAGS=-mod=mod go test ./services/api/internal/config ./services/api/internal/persistence`, disposable `pgvector/pgvector:pg13` integration test, `go test ./services/api/...`, and `task verify:local` passed; no production DB/Secret/cluster access |
## Open Inputs Before Deployment

- Final PoC domain or internal hostname.
- Namespace ownership and GitOps destination.
- Real CNPG database/user provisioning method.
- Redis URL DB split and credential handoff.
- S3 bucket/endpoint/region and path-style requirement.
- SMTP posture.
- Identity posture: local only, Discord OAuth, OIDC, or Hydra/Kratos bridge.
- Elasticsearch/OpenSearch cluster/plugin availability for Chinese analyzer.

## Status Log

- Baseline dependency files identified and used as the source of truth for this board.
- M0 docs/control-plane artifacts created: execution board, render-only K8s base, database bootstrap, S3 compatibility posture, and search architecture.
- S3-compatible endpoint/path-style patch added for CarrierWave and `AgentSessions::S3Storage`; `.env_sample` now includes the new storage knobs.
- Gate G0/G1/G2 checks passed locally; rendered manifests written to `/tmp/noema-rendered.yaml`.
- Local Ruby validation unblocked on 2026-06-03: `mise install ruby@3.3.0` completed, `.mise.toml` now declares `ruby = "3.3.0"`, bundle install completed with `165 Gemfile dependencies, 395 gems`, and targeted S3 specs passed locally with `15 examples, 0 failures` against a disposable `pgvector/pgvector:pg13` PostgreSQL container bound to `127.0.0.1:25432`.
- Local generated-artifact permissions repaired after Docker validation left root-owned `.knapsack_pro`, `coverage`, `.yarn/install-state.gz`, `node_modules`, `log/test.log`, and `app/assets/builds`; `yarn build` now exits 0. The disposable `noema-test-postgres` container was removed after validation.
- Native Go API skeleton landed under `services/api` on 2026-06-03 with only stdlib dependencies: non-secret config loader, `/healthz`, search provider/index seam, and noop bootstrap provider. Verification: initial `go test ./services/api/...` failed before module/skeleton existed, final `go test ./services/api/...` passed, and local smoke returned `{ "service": "noema-api", "status": "ok" }` on unused port `19091` after discovering `18080` was already occupied by local Neko.
- Local verification entrypoints standardized in `Taskfile.yml`: `task verify:local` now runs Go formatting/tests, local API smoke via `scripts/noema_api_smoke.py`, AgentWeGo gate checks, K8s render-only, and `git diff --check`; it passed locally without production access, real Secrets, deploys, or data operations. The smoke helper was hardened to terminate the real process group and a stale-listener check confirmed no leftover processes on ports `19091-19099`.
- Local Elasticsearch index spec builder landed under `services/api/internal/search/elastic` with versioned article index/read-alias naming, JSON-serializable article mapping, and selectable `ngram`/`ik` analyzer specs. This is local-only: no cluster connection, index creation, credentials, plugin assumptions, deploy, or data mutation. Verification: RED `go test ./services/api/internal/search/elastic` failed before production files existed, then `go test ./services/api/...` and `task verify:local` passed.
- Search index specs now cover all current native document families (`articles`, `comments`, `users`, `tags`) via `AllIndexSpecs` plus per-family constructors. Comment/user/tag mappings are still local-only JSON specs and do not assume cluster plugins or mutate indexes. Verification: RED compile failure for missing all-family functions, then `go test ./services/api/internal/search/elastic`, `go test ./services/api/...`, and `task verify:local` passed.
- Search index specs now have a reviewable local manifest envelope and CLI under `services/api/cmd/search-manifest`. `task search:manifest` renders `/tmp/noema-search-index-manifest.json` and verifies `schema_version` plus all four document families; it does not contact Elasticsearch, create indexes, deploy, or read Secrets. Verification: RED compile failure for missing `BuildManifest`/`ManifestJSON`/CLI `run`, then `go test ./services/api/cmd/search-manifest ./services/api/internal/search/elastic`, `go test ./services/api/...`, `task search:manifest`, and `task verify:local` passed.
- Search manifest export now validates itself before JSON output via `ValidateManifest`, rejecting duplicate document/index/alias identities, missing or non-JSON mappings, non-`strict` dynamic mappings, unknown analyzers, and empty manifest identity fields. This is still local-only and produces no external writes. Verification: RED compile failure for missing `ValidateManifest`, then `go test ./services/api/internal/search/elastic ./services/api/cmd/search-manifest`, `go test ./services/api/...`, and `task verify:local` passed.
- Search bootstrap planning now has a local-only review preview via `BuildBootstrapPlan`, `BootstrapPlanJSON`, and `services/api/cmd/search-bootstrap-plan`. Specs now include write aliases (`*-write`) in addition to read aliases, and `task search:bootstrap-plan` writes `/tmp/noema-search-bootstrap-plan.json` with a `review-only` safety marker plus 12 planned create/read-alias/write-alias steps. It does not contact Elasticsearch, create indexes, move aliases, deploy, read Secrets, or mutate data. Verification: RED compile failures for missing `WriteAlias`/`BuildBootstrapPlan`/`BootstrapPlanJSON`/CLI `run`, then `go test ./services/api/internal/search/elastic ./services/api/cmd/search-bootstrap-plan`, `go test ./services/api/...`, `task search:bootstrap-plan`, and `task verify:local` passed.
- PostgreSQL degraded fallback provider stub landed under `services/api/internal/search/fallback`. It registers a `postgres` provider for the native API skeleton, returns empty read results until DB wiring exists, and rejects index mutation methods with `ErrReadOnly`. The native API now selects providers through `search.NewProvider`; the local smoke still reports `search_provider=postgres` without opening DB/Elasticsearch connections or reading Secrets. Verification: RED build failure for missing fallback package/provider selector, then `go test ./services/api/internal/search ./services/api/internal/search/fallback`, `go test ./services/api/...`, `task api:smoke`, and `task verify:local` passed.
- Search rollback planning now has a local-only review preview via `BuildRollbackPlan`, `RollbackPlanJSON`, and `services/api/cmd/search-rollback-plan`. `task search:rollback-plan` writes `/tmp/noema-search-rollback-plan.json` with a `review-only` safety marker plus 12 reverse ordered remove-write-alias/remove-read-alias/delete-index steps. It does not contact Elasticsearch, delete indexes, mutate aliases, deploy, read Secrets, or touch data. Verification: RED compile failures for missing `BuildRollbackPlan`/`RollbackPlanJSON`/CLI `run`, then `go test ./services/api/internal/search/elastic ./services/api/cmd/search-rollback-plan`, `go test ./services/api/...`, `task search:rollback-plan`, and `task verify:local` passed.
- Search provider request normalization is now explicit in `NormalizeSearchRequest`: providers trim query whitespace, default non-positive limits to 20, and clamp oversized limits to 100. Noop and PostgreSQL fallback providers echo the normalized query/limit in local results, which makes provider-contract tests deterministic without contacting DB/Elasticsearch or reading Secrets. Verification: RED compile failures for missing `NormalizeSearchRequest`/limit constants/result echo fields, then `go test ./services/api/internal/search ./services/api/internal/search/fallback`, `go test ./services/api/...`, and `task verify:local` passed.
- Native search runtime config now includes the non-secret bulk planning knobs `ELASTICSEARCH_BULK_SIZE` (default `500`) and `ELASTICSEARCH_REQUEST_TIMEOUT` (default `5s`) in `SearchConfig` and `.env_sample`. This preserves the future Elasticsearch handoff shape while staying local-only: no cluster endpoint, credentials, deploy, or data mutation. Verification: RED compile failure for missing config fields, then `go test ./services/api/internal/config`, `go test ./services/api/...`, and `task verify:local` passed.
- Noop search provider mutation methods now fail closed with `ErrNoopReadOnly` instead of returning nil for indexing operations. This keeps local/test fallback search safe while making accidental write-path usage visible before any real Elasticsearch adapter exists. Verification: RED compile failure for missing `ErrNoopReadOnly`, then `go test ./services/api/internal/search`, `go test ./services/api/...`, and `task verify:local` passed.
- Native persistence seam M0-T28 landed under `services/api/internal/persistence`: minimal Noema-native `User` and `Article` domain records, repository interface, GORM/PostgreSQL implementation, `NOEMA_DATABASE_URL` config boundary, and `task persistence:test`. Inventory coverage cites `app/models/article.rb` (1852 lines, articles/content, target `services/api/internal/articles + search documents`) and `app/models/user.rb` (991 lines, identity/profile, target `services/api/internal/identity`) plus high-impact Article/User edges. This is local-only: tests used disposable `pgvector/pgvector:pg13` on localhost and no production DB, real Secret, deploy, or external mutation. Verification: RED compile failures for missing `DatabaseConfig`/persistence package, then `GOFLAGS=-mod=mod go test ./services/api/internal/config ./services/api/internal/persistence`, disposable PostgreSQL integration tests, `go test ./services/api/...`, and `task verify:local` passed.
