sub vcl_recv {
  if (req.http.Cookie ~ "remember_user_token") {
    set req.http.X-Loggedin = "logged-in";
  } else {
    set req.http.X-Loggedin = "logged-out";
  }
  
  # 1. Capture the original custom domain host header BEFORE we override it.
  # This is critical for Forem's cache isolation (Vary: X-Req-Host).
  set req.http.X-Req-Host = req.http.Host;

  # 2. Safely override the Host header only for custom domains.
  # We do NOT touch the host header if it is already dev.to or www.dev.to.
  if (req.http.Host != "dev.to" && req.http.Host != "www.dev.to" && req.http.Host != "practicaldev.herokuapp.com") {
    # Set X-Forwarded-Host so Rails/Forem can read the custom domain
    if (!req.http.X-Forwarded-Host) {
      set req.http.X-Forwarded-Host = req.http.Host;
    }
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
