# Findings: forem

**Flox feasibility: 8 / 10** · Verified on aarch64-darwin, Flox 1.19.1, 2026-11-17
· Forem `main` at `e7c8eae` (2026-11-17)

## What this repo is

Forem is the open-source platform behind [DEV](https://dev.to). It is by far
the largest and most active project in this folder, and the one where a smooth
contributor setup matters most.

| | |
|---|---|
| Stars / forks | 22,832 / 4,270 |
| Status | Very active (pushed the day of this test) |
| Stack | Rails 8.0.5 on Ruby 3.3.0, Node 22 + Yarn 4, PostgreSQL 13 + pgvector, Redis, Sidekiq, esbuild |
| Native code | ~40 C-extension gems, libvips, ImageMagick, and an in-repo Rust extension (`gems/forem_native`) |
| Existing setup paths | `.devcontainer`, `.gitpod.yml`, `.ona`, `dip.yml`, `docker-compose.yml`, `container-compose.yml`, `Containerfile`, `.mise.toml` + `Brewfile`, `uffizzi/` |

This test started from a plain clone of the public repo. Peter's existing Flox
setup and readiness check were **not** used or seen, so where this overlaps
with his work, his measurements should win.

## What the environment needs

| Need | Source in repo | Flox answer |
|---|---|---|
| Ruby **exactly** 3.3.0 | `.ruby-version`; Gemfile line 5 reads that file verbatim | `ruby_3_3` pinned to `3.3.0` |
| Bundler 2.4.17 | `Gemfile.lock` BUNDLED WITH | Bundler switches to it automatically |
| Node 22.23.4 | `.nvmrc`, `engines.node` | `nodejs_22` pinned to `22.23.4` |
| Yarn 4.1.0 | `.yarnrc.yml` `yarnPath` | Any `yarn` delegates to the committed release |
| PostgreSQL 13 + `vector` extension | `.mise.toml`, `docker-compose.yml`, `db/schema.rb` | `postgresql_13` 13.23 + `pgvector` 0.8.1, as a Flox service |
| Redis | `.mise.toml` (6.0.9), compose (7.0) | `redis` 7.2.4, as a Flox service |
| libvips, ImageMagick | `ruby-vips`, `mini_magick` gems | `vips` 8.15.2 (shared library output), `imagemagick` 7.1.1 |
| OpenSSL, libyaml headers | `openssl` gem (via rpush), `psych` | `openssl` and `libyaml` with `dev` outputs |
| Rust | `gems/forem_native` | Only on aarch64-linux; other platforms use the committed prebuilt binaries |
| 417 gems, 1,415 npm packages | `Gemfile.lock`, `yarn.lock` | `bundle install` and `yarn install --immutable` in the activation hook |

## What floxify did

Created `.flox/env/manifest.toml`. No tracked file was changed: `git status`
shows only `.flox/` as untracked.

The contributor flow is Forem's own scripts, unwrapped:

```bash
flox activate -s
```

```bash
bin/setup
```

```bash
bin/dev
```

`flox activate -s` installs every tool, compiles the gems, installs the npm
packages, initialises a Postgres cluster and starts Postgres and Redis.
`bin/setup` is Forem's existing idempotent script: it creates the database,
loads the schema and seeds it. `bin/dev` runs web, Sidekiq and the esbuild
watcher. All state lives in `.flox/cache`, inside the checkout.

### Decisions worth knowing

- **Four package groups, not one.** Ruby 3.3.0 only exists in an early-2024
  catalog snapshot, and pinning it drags its whole group back to 2024. So
  Ruby and the libraries its native gems link against form one group, Node and
  Yarn resolve current in another, Postgres and pgvector in a third, and Rust
  in a fourth. Each split is recorded in the manifest with the reason.
- **Postgres serves loopback TCP on 5432 as well as a socket.** `bin/setup`
  copies `.env_sample` to `.env`, which hard-codes
  `DATABASE_URL=postgresql://localhost:5432/…`, and `bin/dev` runs foreman,
  which loads `.env` over the shell environment. A socket-only server would be
  unreachable through Forem's own documented path.

## Verified

| Step | Result |
|---|---|
| First activation (gems, npm packages, Postgres cluster) | 78 s, plus ~20 s to finish one gem after a fix |
| `bin/setup` (create, migrate, seed) | 28 s → 15 users, 34 articles, 30 comments, 19 tags |
| `bin/dev` | Web, Sidekiq and JS watcher all started |
| Home page and a seeded article | HTTP 200 (5.5 s cold, 0.45 s warm), title "DEV(local)" |
| pgvector | `CREATE EXTENSION vector` works; distance query returns the right value |
| libvips / ImageMagick | `ruby-vips` loads libvips 8.15.2; `magick` runs |
| RSpec (`forem_native_spec`, `reading_time_spec`) | 238 examples, 1 failure (see below) |
| Warm `flox activate` | 0.25–0.33 s |
| floxify verifier | No violations |

**The 78 seconds is not a clean-machine number.** This Mac had run Flox before
and some packages may already have been in its local store. It says nothing
about the 13-minute cold download Peter measured on a rented Mac.

Not verified: Linux (both platforms are declared in the manifest but were not
run), Intel Macs (excluded, because Node 22.23.4 has no x86_64-darwin build),
the full RSpec suite, Cypress, and any third-party integration.

## Problems found and fixed along the way

Each of these would have hit a new contributor, and each is now handled in the
manifest with a comment explaining it.

1. **`openssl` gem would not compile.** Its headers live in OpenSSL's `dev`
   output, which is not installed by default.
2. **pgvector would not load.** With Postgres in the 2024 snapshot,
   `CREATE EXTENSION vector` failed with `could not access file
   "$libdir/vector"`: that build looks for extensions in its own install, not
   the environment. Moving Postgres to its own group (current Postgres 13.23)
   fixed it. It also mattered for the version: that snapshot carried pgvector
   0.6.2, and Forem's `AGENTS.md` requires 0.8.0 or newer for its HNSW indexes.
3. **Every web request segfaulted on macOS.** Puma forks workers
   (`WEB_CONCURRENCY=2`), and libpq's GSSAPI probe is not safe after `fork()`
   on macOS, so each request crashed in `PG::Connection#connect_start`.
   Setting `PGGSSENCMODE=disable` fixed it. This is a general Rails-on-macOS
   problem, not specific to Flox, and Forem doesn't document it.
4. **`bundle install --jobs` was persisting into `.bundle/config`.** It's now
   passed as an environment variable instead.

## Needs attention

- **`bin/setup` deletes six tracked files.** It turns on Bundler's
  `cache_all`, and Bundler then prunes `vendor/cache/` entries that are no
  longer in `Gemfile.lock` (`emoji_regex`, `gemoji`, `rbs`, `ruby-lsp`,
  `ruby-lsp-rails`, `wcag_color_contrast`). That happens with or without Flox,
  and leaves every new contributor with a dirty tree before their first change.
  These were restored with `git checkout -- vendor/cache`. Removing the stale
  files upstream fixes it.
- **One deterministic spec failure.** `forem_native_spec.rb:3702` fails on
  iteration 0 with a fixed seed: `order_subforem_ids` from the Rust extension
  disagrees with the Ruby reference. It's a pure function, so the environment
  can't cause it. The likely explanation is that the committed Apple Silicon
  binary lags the Rust source; `AGENTS.md` asks contributors to rebuild all
  committed binaries whenever a native symbol changes, which is easy to miss.
  Worth checking against CI. Not confirmed.
- **Rust is only installed on aarch64-linux.** That keeps every contributor
  from downloading a Rust toolchain they don't need. But `AGENTS.md` asks
  anyone changing `gems/forem_native` to run `cargo test`, `clippy` and
  `cargo fmt` locally, so those contributors would add Rust themselves. The
  alternative is shipping Rust to everyone, at a real cost to cold setup time.
  This is a judgement call to make with Peter.
- **Only one Forem checkout can run at a time.** Postgres (5432), Redis (6379)
  and Rails (3000) use fixed ports. Each worktree gets its own database
  cluster under `.flox/cache`, but two worktrees can't serve simultaneously.
  This is the main design question for coding agents (see below).
- **Services live and die with the activation.** Flox stops Postgres and Redis
  when the last `flox activate` that started them exits. That's fine for a
  person in a terminal, but an agent issuing separate `flox activate -c …`
  calls finds the database gone between commands. Hit during this test.
- **The manifest is not the only setup path.** All nine existing setup methods
  still work. Retiring any of them is Forem's call.

## What this suggests for Peter's three questions

**One command from a clean machine.** Honestly, it's three short commands
after installing Flox: `flox activate -s`, `bin/setup`, `bin/dev`. Getting to
one means deciding whether seeding should happen on activation. It can't run in
the activation hook (services start after it), but it could run as a one-shot
service. Separately, installing Flox itself is a step of its own today.

**Fast, predictable cold setup.** This test can't add evidence on network
delivery, but it does show where time goes after packages arrive: about a
minute for gems and npm packages, and 28 seconds to seed. Gem compilation is
the largest piece Flox could take over, for example by publishing a prebuilt
environment.

**Retiring the wrapper; branches and agents.** Three changes would make the
environment safe for parallel agents, all small:

1. Read ports from the environment (`PGPORT`, `REDIS_URL`, `PORT`) and derive
   them per worktree, or serve sockets only. That needs `.env_sample` to stop
   hard-coding TCP.
2. Run services so they outlive a single `-c` command, for example with a
   long-lived `flox activate -s` session per worktree.
3. Fix `bin/setup`'s `vendor/cache` pruning so a fresh checkout stays clean.

A published base environment (runtimes, Postgres, Redis) included from the
repo's `.flox/` would let branches change dependencies without republishing.

## Why the score

Every runtime, library, service and extension Forem needs came from the Flox
catalog, including exact patch pins and pgvector, and the result ran Forem's
own scripts end to end with seeded data. Two points off: the exact Ruby pin
forces a four-group manifest with workarounds a newcomer wouldn't think of,
and parallel agents need changes on Forem's side before they can work
reliably.
