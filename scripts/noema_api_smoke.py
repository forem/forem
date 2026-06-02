#!/usr/bin/env python3
"""Local-only smoke test for the Noema native API skeleton.

Builds the stdlib-only Go API to /tmp, starts it on an unused localhost port,
verifies /healthz, and always tears down the process group and temp binary.
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
import urllib.request
from pathlib import Path


def port_is_free(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.2)
        return sock.connect_ex(("127.0.0.1", port)) != 0


def choose_port() -> int:
    preferred = int(os.environ.get("NOEMA_SMOKE_PORT", "19091"))
    for port in [preferred, *range(19092, 19100)]:
        if port_is_free(port):
            return port
    raise RuntimeError("no free local smoke port found in 19091-19099")


def main() -> int:
    repo = Path(__file__).resolve().parents[1]
    port = choose_port()
    binary_path = Path(tempfile.gettempdir()) / f"noema-api-smoke-{os.getpid()}"
    proc: subprocess.Popen[str] | None = None

    try:
        subprocess.run(
            ["go", "build", "-o", str(binary_path), "./services/api/cmd/api"],
            cwd=repo,
            check=True,
        )

        env = os.environ.copy()
        env.update({"PORT": str(port), "NOEMA_ENV": "test", "SEARCH_PROVIDER": "postgres"})
        proc = subprocess.Popen(
            [str(binary_path)],
            cwd=repo,
            env=env,
            start_new_session=True,
            text=True,
        )

        url = f"http://127.0.0.1:{port}/healthz"
        last_error: Exception | None = None
        for _ in range(30):
            if proc.poll() is not None:
                raise RuntimeError(f"native API exited early with code {proc.returncode}")
            try:
                with urllib.request.urlopen(url, timeout=1) as response:
                    body = response.read().decode("utf-8")
                parsed = json.loads(body)
                print(json.dumps(parsed, indent=4, sort_keys=True))
                if parsed.get("status") != "ok" or parsed.get("service") != "noema-api":
                    raise RuntimeError(f"unexpected health response: {parsed!r}")
                return 0
            except Exception as exc:  # retry during startup
                last_error = exc
                time.sleep(1)

        raise RuntimeError(f"native API smoke check failed on {url}: {last_error}")
    finally:
        if proc is not None and proc.poll() is None:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                proc.wait(timeout=3)
            except Exception:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
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
