# Organization custom domains

Organizations can serve their profile, articles, and pages from their own domain, such as `blog.example.com`. Setup is self-serve for any organization with the `org_custom_domain` feature flag enabled.

Custom domains run on **Cloudflare for SaaS** in front of the existing Fastly edge. Cloudflare issues each domain's certificate. Fastly stays the only cache.

```
visitor ─▶ Cloudflare (custom hostname + certificate)
        ─▶ Worker (rewrites Host to the fallback origin, forwards the real host)
        ─▶ Fastly (trusts the forwarded host behind a shared secret, caches per host)
        ─▶ Rails (routes the host to the organization)
```

## How it works for an organization

1. An org admin opens **Settings → Custom Domain** and enters a domain.
2. The app creates a Cloudflare custom hostname for it and shows a CNAME record pointing at the fallback origin, `cname.<app domain>` by default.
3. Once the record resolves, Cloudflare validates the hostname over HTTP and issues the certificate. A background job polls Cloudflare, every five minutes for the first hour and hourly after that for up to a week.
4. When the hostname and certificate are active, the domain goes live. Links, canonical URLs, and logged-out redirects start using it, and the organization's pages are purged from the cache.

Until a domain is live, the organization keeps using the main domain everywhere, so entering a domain before adding DNS never breaks existing links. The settings page shows Cloudflare's verification errors and has a button to check status, or to retry after a failure.

Removing or changing the domain deletes the Cloudflare hostname. Deleting the organization does too.

## One-time setup

### 1. Cloudflare for SaaS

In the Cloudflare zone for the app domain:

1. Create a **proxied** DNS record for the fallback origin, for example `cname.dev.to`, pointing at the Fastly service.
2. Under **SSL/TLS → Custom Hostnames**, enable Cloudflare for SaaS and set the **Fallback Origin** to that record.
3. Add a **Cache Rule** that bypasses cache when the hostname equals the fallback origin. Cloudflare caches some file extensions by default, and those entries would be shared across every custom domain.
4. Create an API token with **SSL and Certificates: Edit** on the zone.

### 2. Worker

Origin Rules can't rewrite Host or SNI below the Enterprise plan, so a Worker does it. Create a Worker with this code, add a secret named `EDGE_SECRET` (a long random value, for example from `openssl rand -hex 32`), and route it on `*/*` in the zone.

```js
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const host = url.hostname.toLowerCase();

    // Leave the app's own proxied hostnames alone
    if (host === "dev.to" || host.endsWith(".dev.to")) {
      return fetch(request);
    }

    const upstream = new URL(url.pathname + url.search, "https://cname.dev.to");
    const headers = new Headers(request.headers);
    headers.delete("host");
    headers.set("X-Forem-Original-Host", host);
    headers.set("X-Forem-Edge-Secret", env.EDGE_SECRET);

    return fetch(upstream, {
      method: request.method,
      headers,
      body: request.body,
      redirect: "manual",
    });
  },
};
```

Replace `dev.to` and `cname.dev.to` with your app domain and fallback origin. Then add routes with the Worker set to **None** for `<app domain>/*` and `*.<app domain>/*`. The most specific route wins, so the Worker only runs for custom hostnames. Existing routes for specific hosts keep precedence.

Move to Workers Paid before real traffic arrives. On the free plan, requests over the daily limit fail or bypass the Worker, and custom domains don't work without it.

### 3. Fastly

Create an edge dictionary named `forem_edge` on the service. Add the item `cloudflare_secret` with the same value as `EDGE_SECRET`, then activate the version. The VCL snippet in `config/fastly/snippets/check_for_remember_user_token_in_cookie_to_set_header.vcl` only trusts `X-Forem-Original-Host` when that secret matches. It won't compile without the dictionary.

### 4. App configuration

| Variable | Value |
|---|---|
| `CLOUDFLARE_SAAS_API_TOKEN` | The API token from step 1 |
| `CLOUDFLARE_SAAS_ZONE_ID` | The zone ID for the app domain |
| `CLOUDFLARE_SAAS_CNAME_TARGET` | Optional. Defaults to `cname.<app domain>` |

The settings section only appears when both Cloudflare variables are set and the organization has the `org_custom_domain` flag.

## Enabling an organization

```ruby
org = Organization.find_by(slug: "example")
FeatureFlag.enable(:org_custom_domain, FeatureFlag::Actor[org])
```

Flipper values are cached per process, so the section can take a few minutes to appear everywhere.

## Troubleshooting

- **The domain shows the main site's homepage.** Rails did not match the host to an organization. Check that the flag is on for that organization and that `custom_domain` matches exactly. Pages cached before the fix can linger, so purge them with `EdgeCache::Bust.call("https://<domain>/")`.
- **Fastly reports a certificate or SAN error.** The request reached Fastly with the customer hostname as Host or SNI. Check that the Worker route covers the hostname.
- **Every custom domain shows the homepage.** Rails is receiving the fallback origin as the host. Check that the Worker's `EDGE_SECRET` matches the `cloudflare_secret` dictionary item exactly.
- **An organization's status stays pending.** The settings page shows Cloudflare's verification error. The most common causes are a missing CNAME record, a proxied record on Cloudflare DNS, or a conflicting A or AAAA record.

## Legacy Fastly-managed domains

Domains set up before Cloudflare for SaaS point at Fastly directly and use Fastly TLS subscriptions. They keep working unchanged. To move one to Cloudflare:

1. Have the organization change its CNAME to the fallback origin.
2. In a console, run `org.restart_custom_domain_provisioning!`. This creates the Cloudflare hostname and deletes the Fastly TLS subscription.
3. Once the settings page shows the domain as live, remove the domain from the Fastly service.

HTTPS can fail for a few minutes between the DNS change and Cloudflare issuing the certificate.
