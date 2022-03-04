sub vcl_fetch {
  if (req.url == "/" || req.url == "/?i=i") {
    set beresp.stale_while_revalidate = 15s;
  }
}
