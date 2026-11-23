# Developing Forem with Flox

[Flox](https://flox.dev) provides Ruby, Node, Yarn, PostgreSQL with pgvector and
Redis for Forem without installing any of them on your machine, and starts the
app. It is one of several ways to run Forem locally; the Dev Container,
Codespaces, `mise` and `dip` setups in the [README](../README.md) keep working.

## Prerequisites

- [Flox](https://flox.dev/docs/install-flox/) 1.19 or newer, and `git`.
- macOS: nothing else. Flox supplies the compiler, linker and `make`, so the
  Xcode Command Line Tools are not needed; a stock Mac gets `git` from them,
  though, so cloning may prompt you to install them.
- Linux: the usual system time zone data in `/usr/share/zoneinfo` (the `tzdata`
  package). Flox supplies the compiler.
- Apple Silicon Mac, or x86_64 or aarch64 Linux. Node 22.23.4 has no Intel Mac build.

## One command

```bash
git clone https://github.com/forem/forem.git && cd forem && flox activate -s
```

`-s` starts the services. The first run downloads the toolchain, installs gems
and JavaScript packages, creates and seeds the databases, then starts the web
server, Sidekiq, the esbuild watcher, PostgreSQL and Redis, and prints the
address (for example `http://localhost:26052`). Sign in as `admin@forem.local`
with the password `password`; [/dev_tools](dev_tools.md) switches between seeded
accounts. Setup contacts rubygems.org once (for the Bundler version
`Gemfile.lock` names) and the npm registry. Without `-s` nothing is installed.

The services stop when the activation that started them exits. Keep one
`flox activate -s` shell open and run everything else in it:

| To                   | Run                                     |
| -------------------- | --------------------------------------- |
| Run a spec           | `bin/rspec spec/models/tag_spec.rb`     |
| Open a Rails console | `bin/rails console`                     |
| See what is running  | `flox services status`                  |
| Read a service's log | `flox services logs web` (`-f` follows) |
| Reset the databases  | `flox services stop web sidekiq && bin/rails db:reset && flox services start web sidekiq` |

A failed setup shows as `setup Completed (1)` in `flox services status`; read
why with `flox services logs setup`, fix it, exit and activate again.

## Is it ready?

```bash
flox services status --json | jq -e \
  'any(.[]; .name == "setup" and .status == "Completed" and .exit_code == 0)
   and any(.[]; .name == "web" and .status == "Running")'
```

exits `0` when setup succeeded and the web server is running, and `1`
otherwise. The JSON has one object per service, for example
`{"name": "setup", "status": "Completed", "pid": 4242, "exit_code": 0}`.
`status` is `Disabled` while a service waits for setup, and `exit_code` is
`null` while a process runs. The server needs a few more seconds to answer;
`curl --retry 60 --retry-connrefused -fs -o /dev/null http://localhost:$PORT/`
waits for it.

## Several checkouts

Each checkout and each `git worktree` has its own `.flox/cache` (databases,
gems, logs) and derives three ports from its path, so they run side by side.
Set `FOREM_PORT`, `FOREM_PGPORT` or `FOREM_REDIS_PORT` before activating to
choose your own (two paths can, rarely, hash to the same port). Gems are
compiled once per checkout; Yarn keeps its normal global download cache.

## Updating pins

Edit `.flox/env/manifest.toml`, run `flox activate` once (it relocks), and
commit the manifest and `.flox/env/manifest.lock`. `flox upgrade <group>` moves
a package group forward.

- **Ruby (`.ruby-version`):** comes from `flox/ruby_3_3`; switch back to the
  catalog's `ruby_3_3` once `flox show ruby_3_3` lists the version.
  `flox upgrade ruby` picks up a rebuilt package.
- **Node (`.nvmrc`):** change `nodejs.version` and `package.json` `engines` to match.
- **PostgreSQL:** `postgresql.pkg-path` and `pgvector.pkg-path` (CI and
  `docker-compose.yml` use 13).

## Troubleshooting

- **Requests crash with `PG::Connection#connect_start` on macOS:** keep
  `PGGSSENCMODE=disable` if you export your own `PG*` variables.
- **`Address already in use`:** another process holds one of the three ports;
  set the `FOREM_*PORT` variables above.
- **Setup fails:** `flox services logs setup`.
- **The first download crawls (about 1 MB/s) on a fast connection:** Nix fetches
  every package over a single HTTP/2 connection, and some networks limit each
  connection separately. `http2 = false` makes it open one connection per
  download instead. It only works when set for the Nix daemon: as a user
  setting it is ignored (`ignoring the client-specified setting 'http2'`), even
  though `nix config show` reports it. Add `http2 = false` to
  `/etc/nix/nix.conf`, then restart the daemon with
  `sudo launchctl kickstart -k system/org.nixos.nix-daemon` on macOS or
  `sudo systemctl restart nix-daemon.service` on Linux. Elsewhere HTTP/2 is as
  fast or faster, so change it only if downloads are slow.

Outside the checkout, Flox's package store, Yarn's cache and RubyGems' normal
caches are used. PostgreSQL listens on loopback only, with trust authentication.
