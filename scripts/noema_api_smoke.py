#!/usr/bin/env python3
"""Local-only smoke test for the Noema native API skeleton.

Builds the stdlib-only Go API to /tmp, starts it on unused localhost ports,
verifies /healthz, /healthz method errors, /search success, /search JSON error paths,
/legacy-import/identity-preview, /legacy-import/preview, and /legacy-import/batch-preview local-only previews,
unknown-route JSON 404, and unknown-provider fallback,
and always tears down process groups and temp binaries.
"""

from __future__ import annotations

import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path


def port_is_free(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.2)
        return sock.connect_ex(("127.0.0.1", port)) != 0


def choose_port(used: set[int]) -> int:
    preferred = int(os.environ.get("NOEMA_SMOKE_PORT", "19091"))
    for port in [preferred, *range(19092, 19100)]:
        if port not in used and port_is_free(port):
            used.add(port)
            return port
    raise RuntimeError("no free local smoke port found in 19091-19099")


def fetch_json(url: str, *, method: str = "GET", payload: dict | None = None) -> tuple[int, dict]:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=1) as response:
            status = response.status
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        status = exc.code
        body = exc.read().decode("utf-8")
    return status, json.loads(body)


def start_api(repo: Path, binary_path: Path, port: int, provider: str) -> subprocess.Popen[str]:
    env = os.environ.copy()
    env.update({"PORT": str(port), "NOEMA_ENV": "test", "SEARCH_PROVIDER": provider})
    return subprocess.Popen(
        [str(binary_path)],
        cwd=repo,
        env=env,
        start_new_session=True,
        text=True,
    )


def stop_api(proc: subprocess.Popen[str] | None) -> None:
    if proc is None or proc.poll() is not None:
        return
    try:
        os.killpg(proc.pid, signal.SIGTERM)
        proc.wait(timeout=3)
    except Exception:
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def verify_running_api(port: int, expected_provider: str) -> None:
    health_url = f"http://127.0.0.1:{port}/healthz"
    post_health_url = f"http://127.0.0.1:{port}/healthz"
    search_url = f"http://127.0.0.1:{port}/search?q=%20go%20native%20&limit=250"
    bad_limit_url = f"http://127.0.0.1:{port}/search?q=go&limit=not-a-number"
    missing_query_url = f"http://127.0.0.1:{port}/search?q=%20%20&limit=20"
    post_search_url = f"http://127.0.0.1:{port}/search"
    import_preview_url = f"http://127.0.0.1:{port}/legacy-import/preview"
    identity_preview_url = f"http://127.0.0.1:{port}/legacy-import/identity-preview"
    import_batch_preview_url = f"http://127.0.0.1:{port}/legacy-import/batch-preview"
    not_found_url = f"http://127.0.0.1:{port}/does-not-exist"

    status, health = fetch_json(health_url)
    print(json.dumps(health, indent=4, sort_keys=True))
    if (
        status != 200
        or health.get("status") != "ok"
        or health.get("service") != "noema-api"
        or health.get("search_provider") != expected_provider
    ):
        raise RuntimeError(f"unexpected health response: status={status} body={health!r}")

    status, health_method_error = fetch_json(post_health_url, method="POST")
    print(json.dumps(health_method_error, indent=4, sort_keys=True))
    if status != 405 or health_method_error != {"error": "method not allowed"}:
        raise RuntimeError(f"unexpected health method response: status={status} body={health_method_error!r}")

    status, search = fetch_json(search_url)
    print(json.dumps(search, indent=4, sort_keys=True))
    expected_search = {"provider": expected_provider, "query": "go native", "limit": 100, "hits": []}
    if status != 200 or search != expected_search:
        raise RuntimeError(f"unexpected search response: status={status} body={search!r}")

    status, bad_limit = fetch_json(bad_limit_url)
    print(json.dumps(bad_limit, indent=4, sort_keys=True))
    if status != 400 or bad_limit != {"error": "invalid limit"}:
        raise RuntimeError(f"unexpected bad-limit response: status={status} body={bad_limit!r}")

    status, missing_query = fetch_json(missing_query_url)
    print(json.dumps(missing_query, indent=4, sort_keys=True))
    if status != 400 or missing_query != {"error": "missing query"}:
        raise RuntimeError(f"unexpected missing-query response: status={status} body={missing_query!r}")

    status, method_error = fetch_json(post_search_url, method="POST")
    print(json.dumps(method_error, indent=4, sort_keys=True))
    if status != 405 or method_error != {"error": "method not allowed"}:
        raise RuntimeError(f"unexpected method response: status={status} body={method_error!r}")

    preview_payload = {
        "article": {
            "id": 123459,
            "user_id": 42,
            "title": "Composed Import Preview",
            "body_markdown": "Preview body for the composed import bundle.",
            "slug": "composed-import-preview",
            "published": True,
            "published_at": "2026-06-03T03:00:00Z",
            "created_at": "2026-06-03T02:30:00Z",
            "updated_at": "2026-06-03T03:05:00Z",
            "cached_tag_list": "go, native",
        },
        "user": {
            "id": 42,
            "username": "alice",
            "name": "Alice Example",
            "profile_image": "https://example.com/avatar.png",
            "created_at": "2026-06-03T00:00:00Z",
            "updated_at": "2026-06-03T01:30:00Z",
        },
        "email": "alice@example.com",
        "external_identities": [{"provider": "github", "uid": "alice-gh"}],
    }
    status, import_preview = fetch_json(import_preview_url, method="POST", payload=preview_payload)
    print(json.dumps({
        "schema_version": import_preview.get("schema_version"),
        "side_effects": import_preview.get("side_effects"),
        "article_id": import_preview.get("bundle", {}).get("article", {}).get("id"),
        "user_id": import_preview.get("bundle", {}).get("user", {}).get("id"),
        "kratos_identity_id": import_preview.get("kratos", {}).get("identity", {}).get("id"),
        "self_service_flow_count": len(import_preview.get("kratos", {}).get("self_service_flows", [])),
        "operation_plan_count": len(import_preview.get("kratos", {}).get("operation_plans", [])),
    }, indent=4, sort_keys=True))
    if (
        status != 200
        or import_preview.get("schema_version") != "noema.legacy-import.preview/v1"
        or import_preview.get("side_effects") != "none-local-preview-only"
        or import_preview.get("bundle", {}).get("article", {}).get("author_id") != "42"
        or import_preview.get("kratos", {}).get("identity", {}).get("id") != "kratos-preview-identity-42"
        or len(import_preview.get("kratos", {}).get("self_service_flows", [])) != 5
    ):
        raise RuntimeError(f"unexpected import preview response: status={status} body={import_preview!r}")

    status, import_method_error = fetch_json(import_preview_url, method="GET")
    print(json.dumps(import_method_error, indent=4, sort_keys=True))
    if status != 405 or import_method_error != {"error": "method not allowed"}:
        raise RuntimeError(f"unexpected import preview method response: status={status} body={import_method_error!r}")

    identity_payload = {
        "user": preview_payload["user"],
        "email": "alice@example.com",
        "kratos_return_to": "https://noema.local/settings",
        "external_identities": [{"provider": "github", "uid": "alice-gh"}],
    }
    status, identity_preview = fetch_json(identity_preview_url, method="POST", payload=identity_payload)
    identity_operation_plans = identity_preview.get("kratos", {}).get("operation_plans", [])
    identity_flows = identity_preview.get("kratos", {}).get("self_service_flows", [])
    print(json.dumps({
        "schema_version": identity_preview.get("schema_version"),
        "side_effects": identity_preview.get("side_effects"),
        "user_id": identity_preview.get("user", {}).get("id"),
        "kratos_identity_id": identity_preview.get("kratos", {}).get("identity", {}).get("id"),
        "self_service_flow_count": len(identity_flows),
        "operation_plan_count": len(identity_operation_plans),
        "return_to": identity_flows[0].get("return_to") if identity_flows else "",
    }, indent=4, sort_keys=True))
    if (
        status != 200
        or identity_preview.get("schema_version") != "noema.legacy-import.identity-preview/v1"
        or identity_preview.get("side_effects") != "none-local-preview-only"
        or identity_preview.get("user", {}).get("id") != "42"
        or identity_preview.get("kratos", {}).get("identity", {}).get("id") != "kratos-preview-identity-42"
        or len(identity_flows) != 5
        or identity_flows[0].get("return_to") != "https://noema.local/settings"
        or not identity_operation_plans
        or identity_operation_plans[2].get("query", {}).get("return_to") != "https://noema.local/settings"
    ):
        raise RuntimeError(f"unexpected identity preview response: status={status} body={identity_preview!r}")

    status, identity_method_error = fetch_json(identity_preview_url, method="GET")
    print(json.dumps(identity_method_error, indent=4, sort_keys=True))
    if status != 405 or identity_method_error != {"error": "method not allowed"}:
        raise RuntimeError(f"unexpected identity preview method response: status={status} body={identity_method_error!r}")

    batch_payload = {
        "items": [
            preview_payload,
            {
                "article": {
                    "id": 123460,
                    "user_id": 43,
                    "title": "Broken Import Preview",
                    "body_markdown": "This item intentionally omits slug.",
                    "published": True,
                    "published_at": "2026-06-03T03:00:00Z",
                    "created_at": "2026-06-03T02:30:00Z",
                    "updated_at": "2026-06-03T03:05:00Z",
                    "cached_tag_list": "broken",
                },
                "user": {"id": 43, "username": "bob", "name": "Bob Example"},
                "email": "bob@example.com",
            },
        ]
    }
    status, import_batch_preview = fetch_json(import_batch_preview_url, method="POST", payload=batch_payload)
    batch_items = import_batch_preview.get("items", [])
    first_batch_preview = batch_items[0].get("preview", {}) if batch_items else {}
    first_operation_plans = first_batch_preview.get("kratos", {}).get("operation_plans", [])
    print(json.dumps({
        "schema_version": import_batch_preview.get("schema_version"),
        "side_effects": import_batch_preview.get("side_effects"),
        "total": import_batch_preview.get("total"),
        "succeeded": import_batch_preview.get("succeeded"),
        "failed": import_batch_preview.get("failed"),
        "first_item_user_id": first_batch_preview.get("bundle", {}).get("user", {}).get("id"),
        "first_item_operation_plan_count": len(first_operation_plans),
        "second_item_error": batch_items[1].get("error") if len(batch_items) > 1 else "",
    }, indent=4, sort_keys=True))
    if (
        status != 200
        or import_batch_preview.get("schema_version") != "noema.legacy-import.batch-preview/v1"
        or import_batch_preview.get("total") != 2
        or import_batch_preview.get("succeeded") != 1
        or import_batch_preview.get("failed") != 1
        or import_batch_preview.get("side_effects") != "none-local-preview-only"
        or first_batch_preview.get("bundle", {}).get("user", {}).get("id") != "42"
        or not first_operation_plans
        or first_operation_plans[0].get("path") != "/admin/identities"
        or first_operation_plans[0].get("execution") != "review-only"
        or not batch_items[1].get("error")
    ):
        raise RuntimeError(f"unexpected import batch preview response: status={status} body={import_batch_preview!r}")

    status, import_batch_method_error = fetch_json(import_batch_preview_url, method="GET")
    print(json.dumps(import_batch_method_error, indent=4, sort_keys=True))
    if status != 405 or import_batch_method_error != {"error": "method not allowed"}:
        raise RuntimeError(f"unexpected import batch preview method response: status={status} body={import_batch_method_error!r}")

    status, not_found = fetch_json(not_found_url)
    print(json.dumps(not_found, indent=4, sort_keys=True))
    if status != 404 or not_found != {"error": "not found"}:
        raise RuntimeError(f"unexpected not-found response: status={status} body={not_found!r}")


def run_case(repo: Path, binary_path: Path, used_ports: set[int], configured_provider: str, expected_provider: str) -> None:
    port = choose_port(used_ports)
    proc: subprocess.Popen[str] | None = None
    try:
        proc = start_api(repo, binary_path, port, configured_provider)
        last_error: Exception | None = None
        for _ in range(30):
            if proc.poll() is not None:
                raise RuntimeError(f"native API exited early with code {proc.returncode}")
            try:
                verify_running_api(port, expected_provider)
                return
            except Exception as exc:  # retry during startup
                last_error = exc
                time.sleep(1)
        raise RuntimeError(f"native API smoke check failed on port {port}: {last_error}")
    finally:
        stop_api(proc)


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    binary_path = Path(tempfile.gettempdir()) / f"noema-api-smoke-{os.getpid()}"
    used_ports: set[int] = set()
    env = os.environ.copy()
    env.setdefault("GOFLAGS", "-mod=mod")

    try:
        subprocess.run(
            ["go", "build", "-o", str(binary_path), "./services/api/cmd/api"],
            cwd=repo,
            env=env,
            check=True,
        )
        run_case(repo, binary_path, used_ports, "postgres", "postgres")
        run_case(repo, binary_path, used_ports, "does-not-exist", "noop")
        return 0
    finally:
        try:
            binary_path.unlink()
        except FileNotFoundError:
            pass


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"noema native API smoke failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
