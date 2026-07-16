sub vcl_fetch {
  if (req.url == "/" || req.url == "/?i=i") {
    set beresp.stale_while_revalidate = 15s;
  }

  if (beresp.status >= 400) {
    set beresp.ttl = 30s;
    set beresp.cacheable = true;
  }
}
