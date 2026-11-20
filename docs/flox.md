# Developing Forem with Flox

[Flox](https://flox.dev) gives you everything Forem needs to run locally (Ruby,
Node, Yarn, PostgreSQL with pgvector, Redis) without installing any of it on
your machine, and starts the app for you. One command takes a fresh clone to a
running Forem with seed data. Nothing is installed outside the checkout and
Flox's own package store, so it does not touch a Ruby, Node or PostgreSQL you
already have.

This is one of several ways to run Forem locally. The Dev Container, Codespaces,
`mise` and `dip` setups described in the [README](../README.md) keep working.

## What you need first

- [Flox](https://flox.dev/docs/install-flox/) 1.19 or newer.
- `git`.
- **macOS:** the Xcode Command Line Tools (`xcode-select --install`). If you
  have ever run `git` on a Mac you already have them. The Flox Ruby package has
  no compiler in it, and Forem's gems need one to build; on Linux Flox supplies
  `gcc` itself.
- A supported machine: Apple Silicon Macs, and x86_64 or aarch64 Linux. Intel
  Macs are not supported because Node 22.23.4 has no x86_64-darwin build.

## One command

```bash
git clone https://github.com/forem/forem.git && cd forem && flox activate -s
```

On the first activation this downloads the toolchain, installs gems and
JavaScript packages, creates the PostgreSQL cluster, loads the schema, seeds the
database, builds the JavaScript, and then starts the web server, Sidekiq, the
JavaScript watcher, PostgreSQL and Redis. When it finishes, the shell prints the
address, for example `http://localhost:26052`. Open it.

Sign in as `admin@forem.local` with the password `password`. The seed data also
has 14 other users and 34 articles. `/dev_tools` (see
[dev_tools.md](dev_tools.md)) switches between seeded accounts.

Later activations skip the setup and take about a tenth of a second. If you
change `Gemfile.lock`, `yarn.lock` or `db/schema.rb`, the next activation
repeats only what is needed.

The services run for as long as an activation that started them is open. Close
the shell (or `exit`) and they stop. To run commands without an interactive
shell, put them after `-c`:
`flox activate -s -c 'bin/rspec spec/models/tag_spec.rb'`.

## Day to day

Run these from the checkout. Each one starts with `flox activate`; inside an
activated shell, drop that prefix.

| To                          | Run                                                          |
| --------------------------- | ------------------------------------------------------------ |
| Run the tests in one file   | `flox activate -s -c 'bin/rspec spec/models/tag_spec.rb'`    |
| Run one example             | `flox activate -s -c 'bin/rspec spec/models/tag_spec.rb:12'` |
| Open a Rails console        | `flox activate -s -c 'bin/rails console'`                    |
| Restart one service         | `flox services restart web`                                  |
| See a service's logs        | `flox services logs web` (add `-f` to follow)                |
| See what is running         | `flox services status`                                       |
| Reset the databases         | `flox services stop web sidekiq && bin/rails db:reset`       |
| Seed again without dropping | `bin/rails db:seed`                                          |
| Check everything is ready   | `.flox/bin/forem-doctor`                                     |

The services are `postgres`, `redis`, `web`, `sidekiq` and `js` (the esbuild
watcher). Run a command inside a shell that is already activated with `-s` and
the services are already running.

`bin/rails db:reset` recreates both the development and the test databases and
reseeds the development one. It leaves `db/schema.rb` untouched: the PostgreSQL
cluster uses the `en_US.UTF-8` collation, which is the order the committed file
was written in.

## Is it ready? (`forem-doctor`)

```bash
flox activate -c '.flox/bin/forem-doctor'
```

prints one JSON document and exits `0` when every component is ready, `1` when
one is not. Each component says what it expected, what it found and, when it is
not ready, what to run:

```json
{
  "ready": false,
  "ports": { "web": 26052, "postgres": 26053, "redis": 26054 },
  "components": {
    "ruby": { "ready": true, "expected": "3.3.14", "actual": "3.3.14" },
    "redis": {
      "ready": false,
      "actual": "127.0.0.1:26054",
      "fix": "flox services start"
    }
  }
}
```

(Abbreviated. The full report also covers the compiler, Node, Yarn, Bundler,
gems, `node_modules`, the esbuild output, the PostgreSQL version and pgvector,
pending migrations, seed rows and `GET /`.)

Options:

- `--wait SECONDS` keeps checking until ready or the timeout, which suits a
  script or coding agent that has just started the services.
- `--skip NAME[,NAME]` leaves components out, e.g. `--skip web` before the
  services start.
- `--self-test` runs checks that need no running services.

Versions are compared with the repository's own pin files: `.ruby-version`,
`.nvmrc`, `.yarnrc.yml`, `Gemfile.lock` and the PostgreSQL version in
`docker-compose.yml`.

## Several checkouts at once

Every checkout, including every `git worktree`, has its own `.flox` state and
derives three consecutive ports from its path, so two can run side by side:

```bash
git worktree add ../forem-fix-123 -b fix-123 && cd ../forem-fix-123 && flox activate -s
```

Each checkout gets its own PostgreSQL data, Redis, logs and pid files under
`.flox/cache`. What they share is not rebuilt: the Flox packages, the compiled
gems (kept in `~/.cache/forem-flox/gems`, one directory per Ruby build) and
Yarn's download cache. A second checkout therefore skips gem compilation, and
its first activation takes seconds instead of minutes. The ports are printed on
activation and appear in `forem-doctor`. Set `FOREM_PORT`, `FOREM_PGPORT` or
`FOREM_REDIS_PORT` before activating to choose your own (two paths can, rarely,
hash to the same port).

## Coding agents

Everything above is plain commands, and `.flox/bin/forem-doctor` gives an agent
a machine-readable answer. Services stop when the activation that started them
exits, so an agent that runs one command per activation should either use
`flox activate -s -c '<command>'` each time or keep one long-lived activation
open: `flox activate -s -c 'sleep infinity' &`. Other `flox activate`
invocations in the same checkout then find the services running.

## Troubleshooting

**`forem-bootstrap: the Xcode Command Line Tools are missing`.** Run
`xcode-select --install`, then activate again.

**Output ends with `forem-bootstrap failed; logs in …/.flox/cache/bootstrap/`.**
The log named after the step that failed (`gems.log`, `js.log`, `devdb.log`) is
in that directory. After fixing the cause, `rm .flox/cache/bootstrap/ready` and
activate again; the bootstrap is safe to repeat.

**`git status` shows changes in `vendor/cache` or `db/schema.rb` after setup.**
It should not. Bundler 2.4.17 (the version in `Gemfile.lock`) is installed
during setup for this reason, because a newer Bundler rewrites the committed git
gem in `vendor/cache`. If it happens, please report it.

**Web requests crash with `PG::Connection#connect_start` on macOS.** The
environment sets `PGGSSENCMODE=disable` for this (libpq's GSSAPI probe is not
safe after Puma forks). If you export your own `PG*` variables, keep that one.

**Redis exits at startup on Linux with a locale error.** The environment starts
Redis with `LC_ALL=C` because the Nix C library has no data for the host's
locale. A Redis you start by hand needs the same.

**`Address already in use`.** Another process holds one of the three ports.
`forem-doctor` prints them; choose others with `FOREM_PORT`, `FOREM_PGPORT` and
`FOREM_REDIS_PORT`, or stop the other process.

**The page loads but is unstyled.** The JavaScript is not built yet:
`forem-doctor` reports `js_build` not ready. Run `yarn build`, or wait for the
`js` service.

**Web does not come back after `flox services restart web`.** It takes about
five seconds. If `flox services status` still does not show it running, read
`flox services logs web`.

## Updating pins

The environment follows the repository's version files; when one changes, the
manifest has to follow. `forem-doctor` reports a mismatch.

- **`.ruby-version`:** Ruby comes from the `flox/ruby_3_3` package, which
  follows the 3.3 security releases. Once the Flox catalog's own `ruby_3_3`
  lists the version in `.ruby-version` (`flox show ruby_3_3`), switch
  `ruby.pkg-path` back to `ruby_3_3` and set `ruby.version`. Ruby 3.3 reaches
  end of support at the end of March 2027; the line then moves to the series
  `.ruby-version` names. After any change run `flox lock-manifest` and commit
  `.flox/env/manifest.lock`. The `gcc.version` on Linux must follow the Ruby
  package's nixpkgs snapshot (see the comment in the manifest).
- **`.nvmrc`:** change `nodejs.version` in `.flox/env/manifest.toml` to the same
  value, and keep `package.json`'s `engines.node` consistent.
- **Yarn:** nothing to do. `.yarnrc.yml` points `yarnPath` at the committed
  release, which `.flox/bin/yarn` runs with the environment's Node.
- **PostgreSQL major version:** `postgresql.pkg-path` and `pgvector.pkg-path`
  (for example `postgresql_16` and `postgresql16Packages.pgvector`). CI and
  `docker-compose.yml` use 13.

## How it is put together

`.flox/env/manifest.toml` lists the packages (every non-obvious choice has a
comment), starts the five services, and in its activation hook derives the ports
and shared gem directory. `.flox/bin/forem-bootstrap` runs from that hook and
does the Forem-specific work in parallel lanes: gems, JavaScript, database
cluster, development and test databases. It does nothing when nothing changed.
`.flox/bin/forem-doctor` is the readiness check. `.flox/bench/contrib-ready.sh`
times a fresh clone through to a passing spec; the `Flox cold start` workflow
runs it on Linux and macOS whenever `.flox` changes.
