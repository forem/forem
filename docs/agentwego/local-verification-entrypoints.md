# Noema Local Verification Entrypoints

## Scope

This document records the local-only verification tasks added for Noema M0 work. These commands are intentionally safe:

- no production access;
- no real Secret reads or writes;
- no database/user/bucket/index creation;
- no Kubernetes apply/deploy;
- no irreversible data operations.

## Taskfile Entrypoints

`Taskfile.yml` adds the following commands:

| Task | Purpose | Side effects |
| --- | --- | --- |
| `task go:fmt` | Format native Go API skeleton files. | Rewrites local Go files only. |
| `task go:test` | Run `go test ./services/api/...`. | None beyond Go test cache. |
| `task api:smoke` | Run `scripts/noema_api_smoke.py`: build the native API to `/tmp`, start it on an unused local port, verify `/healthz`, then terminate the process group and remove the temp binary. | Starts and kills a local process; writes a temporary `/tmp/noema-api-smoke-*` binary. |
| `task agentwego:gates` | Check inventory counts and control-plane docs. | Read-only. |
| `task k8s:render` | Render `deploy/k8s/base` to `/tmp/noema-rendered.yaml`. | Writes `/tmp/noema-rendered.yaml`; never applies. |
| `task search:manifest` | Render the native search index manifest to `/tmp/noema-search-index-manifest.json` and validate schema/family coverage. | Writes a local `/tmp` JSON artifact only; never contacts Elasticsearch. |
| `task verify:local` | Run the current low-risk local validation chain. | Formatting, local test cache, temporary local process, `/tmp` manifest/render output. |

## Verification Output

`task --list` parsed the Taskfile and listed all entries:

```text
* agentwego:gates
* api:smoke
* go:fmt
* go:test
* k8s:render
* search:manifest
* verify:local
```

Full local verification passed:

```bash
task verify:local
```

Key outputs:

```text
?   	github.com/agentwego/noema/services/api/cmd/api	[no test files]
ok  	github.com/agentwego/noema/services/api/cmd/search-manifest	(cached)
ok  	github.com/agentwego/noema/services/api/internal/config	(cached)
ok  	github.com/agentwego/noema/services/api/internal/http	(cached)
ok  	github.com/agentwego/noema/services/api/internal/search	(cached)
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	(cached)
search manifest ok 4
```

Native API smoke output:

```json
{
  "env": "test",
  "search_provider": "postgres",
  "service": "noema-api",
  "status": "ok"
}
```

AgentWeGo gate output included:

```text
inventory ok 5900
```

Kubernetes render-only output included the expected non-applied resources:

```text
kind: Namespace
kind: Service
kind: Deployment
kind: Deployment
kind: Job
```

Final whitespace check:

```bash
git diff --check
# exits 0
```

## Rollback

Remove `Taskfile.yml`, this document, and the corresponding M0-T8/M0-T11 execution-board references. If only rolling back manifest export, remove `task search:manifest`, the `verify:local` manifest step, and the M0-T11 references.
