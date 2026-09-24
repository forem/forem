sub vcl_fetch {
  if (req.url == "/" || req.url == "/?i=i") {
    set beresp.stale_while_revalidate = 60s;
  }

  # Cache error responses briefly to protect origin from repeated error traffic,
  # but NEVER cache errors for API routes. API error responses (401, 429, etc.)
  # are per-request and per-user (keyed by the api-key header which is not part
  # of the Fastly cache key). Caching them causes valid authenticated requests
  # to receive stale error responses from other users or rate-limit windows.
  if (beresp.status >= 400 && !(req.url ~ "^/api")) {
    set beresp.ttl = 30s;
    set beresp.cacheable = true;
  }
}
