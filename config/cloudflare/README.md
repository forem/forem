# Cloudflare Edge Configuration for Forem

This directory contains a portable Cloudflare Edge configuration that mirrors the Fastly VCL snippets in `config/fastly/snippets/` 1:1.

## VCL-to-Cloudflare Mapping

| Fastly VCL Snippet (`config/fastly/snippets/`) | Cloudflare Worker Equivalent (`config/cloudflare/worker.js`) |
| :--- | :--- |
| `bad_bot_detection.vcl` | `isBadBot(userAgent, pathname)` — Returns `403 Forbidden Bots` for disallowed scrapers and non-API `Ruby` user-agents. |
| `safe_params_list.vcl` | `filterSafeParams(url, headers)` — Strips unknown query parameters unless the path is `/ahoy/`, `/admin/`, `/search/`, `/bulk_show`, or `/api` with an `api-key` header. |
| `client_geolocation.vcl` | `resolveGeolocation(request.cf, activeRegions)` — Populates `X-Client-Geo` and `X-Cacheable-Client-Geo` from `request.cf.country` and `request.cf.regionCode`. |
| `check_for_remember_user_token_in_cookie_to_set_header.vcl` | `resolveHostAndAuthHeaders(...)` + `applyEdgeResponseHeaders(...)` — Sets `X-Loggedin` (`logged-in` / `logged-out`), isolates custom domain hosts via `X-Req-Host` / `X-Forem-Original-Host`, and enforces `Vary`. |
| `stale_while_revalidate_controls.vcl` | `applyEdgeResponseHeaders(...)` — Applies `stale-while-revalidate=60` on `/` and `/?i=i`, caches non-`/api` `>= 400` responses for 30s, and translates `Surrogate-Control` → `CDN-Cache-Control` and `Surrogate-Key` → `Cache-Tag`. |

## Environment Variables (Rails Application)

Configure the following environment variables on your Forem instance to switch edge operations from Fastly to Cloudflare:

- `CLOUDFLARE_API_TOKEN` — Cloudflare API token with **Zone > Cache Purge** (and **Zone > SSL and Certificates** for custom domains, or **Account > Workers Scripts** for `rake cloudflare:update_configs`).
- `CLOUDFLARE_ZONE_ID` — Target Cloudflare Zone ID for URL purging (`EdgeCache::Bust::Cloudflare`), tag purging (`EdgeCache::PurgeByKey` / `Purgeable`), and Custom Hostname TLS (`CloudflareTls::Client`).
- `CLOUDFLARE_ACCOUNT_ID` & `CLOUDFLARE_WORKER_NAME` *(optional)* — Used by `bundle exec rake cloudflare:update_configs` (`CloudflareConfig::Update`) to upload `config/cloudflare/worker.js` via the Cloudflare API.
- `CLOUDFLARE_CDN_URL` *(optional)* — Asset host URL fallback for `config.action_controller.asset_host` when `FASTLY_CDN_URL` is unset.
