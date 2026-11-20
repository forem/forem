sub vcl_fetch {
  if (req.url == "/" || req.url == "/?i=i") {
    set beresp.stale_while_revalidate = 60s;
  }

  # Cache error responses briefly to protect origin from repeated error traffic,
  # but NEVER cache errors for API routes, 429 rate-limit responses, or
  # explicitly uncacheable (`private` / `no-store`) responses.
  # Snippets created via FastlyConfig::Snippets run as `type: "init"` before
  # `#FASTLY fetch`, which overwrites `beresp.ttl` with the service Default TTL
  # when `Surrogate-Control` / `Cache-Control` lacks `max-age` (such as Rails's
  # `PublicExceptions` 404 page). Setting `Surrogate-Control = "max-age=30"`
  # keeps `#FASTLY fetch` at 30s and gets stripped automatically on delivery.
  if (beresp.status >= 400 && beresp.status != 429 && !(req.url ~ "^/api") && (!beresp.http.Cache-Control || beresp.http.Cache-Control !~ "(private|no-store)")) {
    set beresp.http.Surrogate-Control = "max-age=30";
    set beresp.ttl = 30s;
    set beresp.cacheable = true;
  }
}
