sub vcl_recv {
  if (req.http.Cookie ~ "remember_user_token" || req.http.Cookie ~ "forem_user_signed_in") {
    set req.http.X-Loggedin = "logged-in";
  } else {
    set req.http.X-Loggedin = "logged-out";
  }
  set req.http.X-Req-Host = req.http.Host;
}

sub vcl_fetch {
  if (beresp.http.Vary !~ "X-Loggedin") {
    if (beresp.http.Vary) {
      set beresp.http.Vary = beresp.http.Vary ", X-Loggedin";
    } else {
      set beresp.http.Vary = "X-Loggedin";
    }
  }
  if (req.http.Host == "dev.to") {
    if (beresp.http.Vary && beresp.http.Vary ~ "X-Req-Host") {
      set beresp.http.Vary = regsub(beresp.http.Vary, "(,?\\s*X-Req-Host)", "");
      set beresp.http.Vary = regsub(beresp.http.Vary, "^,\\s*", "");
      set beresp.http.Vary = regsub(beresp.http.Vary, ",\\s*$", "");
      if (beresp.http.Vary == "") {
        unset beresp.http.Vary;
      }
    }
  } else {
    if (beresp.http.Vary !~ "X-Req-Host") {
      if (beresp.http.Vary) {
        set beresp.http.Vary = beresp.http.Vary ", X-Req-Host";
      } else {
        set beresp.http.Vary = "X-Req-Host";
      }
    }
  }
}
