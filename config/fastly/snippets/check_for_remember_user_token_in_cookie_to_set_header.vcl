sub vcl_recv {
  if (req.http.Cookie ~ "remember_user_token" || req.http.Cookie ~ "forem_user_signed_in") {
    set req.http.X-Loggedin = "logged-in";
  } else {
    set req.http.X-Loggedin = "logged-out";
  }
}

sub vcl_fetch {
  # Vary on the custom header, don't add if shield POP already added
  if (beresp.http.Vary !~ "X-Loggedin") {
    if (beresp.http.Vary) {
      set beresp.http.Vary = beresp.http.Vary ", X-Loggedin";
    } else {
      set beresp.http.Vary = "X-Loggedin";
    }
  }
}
