sub vcl_recv {
  if (req.http.Cookie ~ "remember_user_token") {
    set req.http.X-Loggedin = "logged-in";
  } else {
    set req.http.X-Loggedin = "logged-out";
  }
  
  # 0. X-Req-Host is only trustworthy when our own service set it earlier: on the
  # edge POP before forwarding to the shield, or before a restart. Drop any value
  # a client sent directly so it cannot choose the host Rails renders for.
  if (fastly.ff.visits_this_service == 0 && req.restarts == 0) {
    unset req.http.X-Req-Host;
  }

  # 1. Capture the original custom domain host header BEFORE we override it.
  # This is critical for Forem's cache isolation (Vary: X-Req-Host).
  if (req.http.X-Req-Host) {
    # On the Shield POP: Since X-Req-Host is already set to the client host (e.g. mlh.forem.wtf),
    # we use it to restore all other tracking headers.
    set req.http.Fastly-Orig-Host = req.http.X-Req-Host;
    set req.http.X-Forwarded-Host = req.http.X-Req-Host;
    set req.http.X-Forem-Original-Host = req.http.X-Req-Host;
  } else {
    # On the Edge POP.
    # Org custom domains served through Cloudflare for SaaS arrive from a Cloudflare
    # Worker with Host set to the fallback origin and the customer's hostname in
    # X-Forem-Original-Host. Only trust that header when the shared secret matches
    # the cloudflare_secret item in the forem_edge edge dictionary (compared in
    # constant time) and the value is a plain lowercase hostname. Note that VCL
    # strings have no backslash escapes, so "\." in a regex is a literal dot.
    set req.http.X-Forem-Original-Host = std.tolower(req.http.X-Forem-Original-Host);
    if (std.strlen(req.http.X-Forem-Edge-Secret) > 0
        && digest.secure_is_equal(req.http.X-Forem-Edge-Secret, table.lookup(forem_edge, "cloudflare_secret", ""))
        && std.strlen(req.http.X-Forem-Original-Host) <= 253
        && req.http.X-Forem-Original-Host ~ "^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$") {
      set req.http.X-Req-Host = req.http.X-Forem-Original-Host;
    } else {
      # Direct traffic: capture from the client's Host header.
      set req.http.X-Req-Host = req.http.Host;
    }
    set req.http.Fastly-Orig-Host = req.http.X-Req-Host;
    set req.http.X-Forwarded-Host = req.http.X-Req-Host;
    set req.http.X-Forem-Original-Host = req.http.X-Req-Host;
  }

  # Never forward the shared secret to the shield or to Heroku.
  unset req.http.X-Forem-Edge-Secret;

  # 2. Safely override the Host header only for custom domains.
  # We do NOT touch the host header if it is already dev.to or www.dev.to.
  if (req.http.Host != "dev.to" && req.http.Host != "www.dev.to" && req.http.Host != "practicaldev.herokuapp.com") {
    # Rewrite the Host header to match the Heroku application domain
    set req.http.Host = "practicaldev.herokuapp.com";
  }
}

sub vcl_fetch {
  if (beresp.http.Vary !~ "X-Loggedin") {
    if (beresp.http.Vary) {
      set beresp.http.Vary = beresp.http.Vary ", X-Loggedin";
    } else {
      set beresp.http.Vary = "X-Loggedin";
    }
  }
  
  # 3. Check if the original request was for dev.to (stored in X-Req-Host)
  if (req.http.X-Req-Host == "dev.to" || req.http.X-Req-Host == "www.dev.to") {
    if (beresp.http.Vary && beresp.http.Vary ~ "X-Req-Host") {
      set beresp.http.Vary = regsub(beresp.http.Vary, "(,?\\s*X-Req-Host)", "");
      set beresp.http.Vary = regsub(beresp.http.Vary, "^,\\s*", "");
      set beresp.http.Vary = regsub(beresp.http.Vary, ",\\s*$", "");
      if (beresp.http.Vary == "") {
        unset beresp.http.Vary;
      }
    }
  } else {
    # For custom domains, vary cache on X-Req-Host to prevent cache collisions
    if (beresp.http.Vary !~ "X-Req-Host") {
      if (beresp.http.Vary) {
        set beresp.http.Vary = beresp.http.Vary ", X-Req-Host";
      } else {
        set beresp.http.Vary = "X-Req-Host";
      }
    }
  }
}
