sub vcl_recv {
  declare local var.cd_req_host STRING;
  declare local var.cd_app_domain STRING;
  declare local var.cd_dict_key STRING;
  declare local var.cd_slug STRING;
  declare local var.cd_domain STRING;
  declare local var.cd_return_to STRING;
  declare local var.cd_rt_path STRING;
  declare local var.cd_rt_qs STRING;
  declare local var.cd_target_path STRING;
  declare local var.cd_clean_qs STRING;
  declare local var.cd_seg1 STRING;
  declare local var.cd_seg2 STRING;
  declare local var.cd_is_org_route BOOL;

  if (req.http.Cookie ~ "remember_user_token") {
    set req.http.X-Loggedin = "logged-in";
  } else {
    set req.http.X-Loggedin = "logged-out";
  }
  
  # 0. X-Req-Host and internal redirect/cookie headers are only trustworthy when
  # our own service set them earlier. Drop any value a client sent directly.
  if (fastly.ff.visits_this_service == 0 && req.restarts == 0) {
    unset req.http.X-Req-Host;
    unset req.http.X-Forem-Set-Cd-Anon;
    unset req.http.X-Forem-Redirect-Location;
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

  # 1b. Edge-only auth redirects between main app domain and organization custom domains.
  if (fastly.ff.visits_this_service == 0 && req.restarts == 0) {
    set var.cd_req_host = std.tolower(regsub(req.http.X-Req-Host, ":[0-9]+$", ""));
    set var.cd_app_domain = std.tolower(table.lookup(custom_domain_orgs, "app_domain", "dev.to"));

    if (var.cd_req_host == var.cd_app_domain || var.cd_req_host == "www." + var.cd_app_domain) {
      # Dedicated synthetic endpoint used by custom domains to inspect main-domain auth state.
      if (req.url.path == "/__forem_cd_auth_check") {
        if (req.request != "GET" && req.request != "HEAD") {
          error 753;
        }

        set var.cd_domain = std.tolower(urldecode(subfield(req.url.qs, "domain", "&")));
        if (std.strlen(var.cd_domain) == 0
            || std.strlen(var.cd_domain) > 253
            || var.cd_domain !~ "^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$") {
          error 753;
        }

        set var.cd_dict_key = "domain:" + var.cd_domain;
        set var.cd_slug = table.lookup(custom_domain_orgs, var.cd_dict_key, "");
        if (var.cd_slug == "") {
          error 753;
        }

        set var.cd_return_to = urldecode(subfield(req.url.qs, "return_to", "&"));
        if (var.cd_return_to == ""
            || std.strlen(var.cd_return_to) > 2048
            || var.cd_return_to !~ "^/([^/\\]|$)"
            || var.cd_return_to ~ "[[:cntrl:] ]") {
          set var.cd_return_to = "/";
        }

        if (var.cd_return_to ~ "\?") {
          set var.cd_rt_path = regsub(var.cd_return_to, "\?.*$", "");
          set var.cd_rt_qs = regsub(var.cd_return_to, "^[^?]*\?", "");
        } else {
          set var.cd_rt_path = var.cd_return_to;
          set var.cd_rt_qs = "";
        }

        if (var.cd_rt_qs != "") {
          set var.cd_rt_qs = regsuball(var.cd_rt_qs, "(^|&)cd_anon=[^&]*", "");
          set var.cd_rt_qs = regsub(var.cd_rt_qs, "^&+", "");
        }

        if (req.http.X-Loggedin == "logged-in") {
          if (var.cd_rt_path == "/" || var.cd_rt_path == "") {
            set var.cd_target_path = "/" + var.cd_slug;
          } else if (std.tolower(var.cd_rt_path) == "/" + var.cd_slug
                     || std.prefixof(std.tolower(var.cd_rt_path), "/" + var.cd_slug + "/")) {
            set var.cd_target_path = var.cd_rt_path;
          } else {
            set var.cd_target_path = "/" + var.cd_slug + var.cd_rt_path;
          }

          if (var.cd_rt_qs != "") {
            set req.http.X-Forem-Redirect-Location = "https://" + var.cd_app_domain + var.cd_target_path + "?" + var.cd_rt_qs;
          } else {
            set req.http.X-Forem-Redirect-Location = "https://" + var.cd_app_domain + var.cd_target_path;
          }
          error 752;
        } else {
          if (var.cd_rt_qs != "") {
            set req.http.X-Forem-Redirect-Location = "https://" + var.cd_domain + var.cd_rt_path + "?" + var.cd_rt_qs + "&cd_anon=1";
          } else {
            set req.http.X-Forem-Redirect-Location = "https://" + var.cd_domain + var.cd_rt_path + "?cd_anon=1";
          }
          error 752;
        }
      }

      # Signed-out main-domain requests to custom-domain org profiles, custom pages, and articles.
      if ((req.request == "GET" || req.request == "HEAD")
          && req.http.X-Loggedin == "logged-out"
          && subfield(req.url.qs, "mode", "&") != "embed"
          && (!req.http.Sec-Fetch-Dest || req.http.Sec-Fetch-Dest != "iframe")
          && (!req.http.Accept || req.http.Accept ~ "(text/html|\*/\*)")
          && subfield(req.url.qs, "view", "&") !~ "^(comments|moderate|admin)$") {
        set var.cd_seg1 = "";
        set var.cd_target_path = "";

        if (req.url.path ~ "^/[a-zA-Z0-9_-]+/?$") {
          set var.cd_seg1 = std.tolower(regsub(req.url.path, "^/([a-zA-Z0-9_-]+)/?$", "\1"));
          set var.cd_target_path = "/";
        } else if (req.url.path ~ "^/[a-zA-Z0-9_-]+/p/[^/?#.]+/?$") {
          set var.cd_seg1 = std.tolower(regsub(req.url.path, "^/([a-zA-Z0-9_-]+)/p/([^/?#.]+)/?$", "\1"));
          set var.cd_seg2 = regsub(req.url.path, "^/([a-zA-Z0-9_-]+)/p/([^/?#.]+)/?$", "\2");
          set var.cd_target_path = "/p/" + var.cd_seg2;
        } else if (req.url.path ~ "^/[a-zA-Z0-9_-]+/[^/?#.]+/?$") {
          set var.cd_seg1 = std.tolower(regsub(req.url.path, "^/([a-zA-Z0-9_-]+)/([^/?#.]+)/?$", "\1"));
          set var.cd_seg2 = regsub(req.url.path, "^/([a-zA-Z0-9_-]+)/([^/?#.]+)/?$", "\2");
          if (std.tolower(var.cd_seg2) !~ "^(members|settings|series|comments|moderate|admin|profile_pins|comment|embed|p)$") {
            set var.cd_target_path = "/" + var.cd_seg2;
          } else {
            set var.cd_seg1 = "";
          }
        }

        if (var.cd_seg1 != "" && var.cd_target_path != "") {
          set var.cd_dict_key = "slug:" + var.cd_seg1;
          set var.cd_domain = table.lookup(custom_domain_orgs, var.cd_dict_key, "");
          if (var.cd_domain != "") {
            if (subfield(req.url.qs, "i", "&") != "") {
              error 754;
            }

            set var.cd_clean_qs = regsuball(req.url.qs, "(^|&)cd_anon=[^&]*", "");
            set var.cd_clean_qs = regsub(var.cd_clean_qs, "^&+", "");
            if (var.cd_clean_qs != "") {
              set req.http.X-Forem-Redirect-Location = "https://" + var.cd_domain + var.cd_target_path + "?" + var.cd_clean_qs + "&cd_anon=1";
            } else {
              set req.http.X-Forem-Redirect-Location = "https://" + var.cd_domain + var.cd_target_path + "?cd_anon=1";
            }
            error 752;
          }
        }
      }
    } else if (var.cd_req_host != "") {
      set var.cd_dict_key = "domain:" + var.cd_req_host;
      set var.cd_slug = table.lookup(custom_domain_orgs, var.cd_dict_key, "");

      if (var.cd_slug != "") {
        # Strip cd_anon=1 before cache lookup so clean and post-check URLs share one cache entry,
        # and signal vcl_deliver to attach the short-lived first-party cd_anon cookie.
        if (subfield(req.url.qs, "cd_anon", "&") == "1") {
          set req.http.X-Forem-Set-Cd-Anon = "1";
          set var.cd_clean_qs = regsuball(req.url.qs, "(^|&)cd_anon=[^&]*", "");
          set var.cd_clean_qs = regsub(var.cd_clean_qs, "^&+", "");
          if (var.cd_clean_qs != "") {
            set req.url = req.url.path + "?" + var.cd_clean_qs;
          } else {
            set req.url = req.url.path;
          }
        }

        if ((req.request == "GET" || req.request == "HEAD")
            && subfield(req.url.qs, "mode", "&") != "embed"
            && (!req.http.Sec-Fetch-Dest || req.http.Sec-Fetch-Dest != "iframe")
            && subfield(req.url.qs, "i", "&") == ""
            && (!req.http.Accept || req.http.Accept ~ "(text/html|\*/\*)")) {
          set var.cd_is_org_route = false;

          if (req.url.path == "/" || req.url.path ~ "^/p/[^/?#.]+/?$") {
            set var.cd_is_org_route = true;
          } else if (std.prefixof(std.tolower(req.url.path), "/" + var.cd_slug + "/")
                     && req.url.path ~ "^/[a-zA-Z0-9_-]+/[^/?#.]+/?$") {
            set var.cd_is_org_route = true;
          } else if (req.url.path ~ "^/[^/?#.]+/?$") {
            set var.cd_seg1 = std.tolower(regsub(req.url.path, "^/([^/?#.]+)/?$", "\1"));
            if (var.cd_seg1 !~ "^(ahoy|api|assets|async_info|auth_pass|badge_achievements|bb|bb_tabulations|billboard_events|billboards|display_ad_events|display_ads|enter|fallback_activity_recorder|feedback_messages|feed_events|followed_articles|lead_submissions|packs|poll_votes|rails|reactions|reading_list_items|search|sign_out|signout_confirm|users|feed|rss|robots|sitemap|llms|embed|serviceworker|manifest|open-search|settings|dashboard|notifications|readinglist|new|mod|admin|internal|leaderboard|community|pod|podcasts|tags|t|top|latest|latest_less_filtered|discover|following|curated|onboarding|menu|curation|leadership)$") {
              set var.cd_is_org_route = true;
            }
          }

          if (var.cd_is_org_route) {
            if (req.http.X-Loggedin == "logged-in") {
              if (req.url.path == "/") {
                set var.cd_target_path = "/" + var.cd_slug;
              } else if (std.tolower(req.url.path) == "/" + var.cd_slug
                         || std.prefixof(std.tolower(req.url.path), "/" + var.cd_slug + "/")) {
                set var.cd_target_path = req.url.path;
              } else {
                set var.cd_target_path = "/" + var.cd_slug + req.url.path;
              }

              if (req.url.qs != "") {
                set req.http.X-Forem-Redirect-Location = "https://" + var.cd_app_domain + var.cd_target_path + "?" + req.url.qs;
              } else {
                set req.http.X-Forem-Redirect-Location = "https://" + var.cd_app_domain + var.cd_target_path;
              }
              error 752;
            } else if (req.http.Cookie:cd_anon != "1"
                       && req.http.X-Forem-Set-Cd-Anon != "1"
                       && req.http.Sec-Fetch-Dest == "document"
                       && (!req.http.Sec-Fetch-Mode || req.http.Sec-Fetch-Mode == "navigate")
                       && req.http.User-Agent !~ "(?i)(bot|crawl|spider|slurp|facebookexternalhit|whatsapp|slack|discord|twitter|linkedin|telegram|pinterest|embedly|quora|outbrain|vkshare|w3c_validator|lighthouse|pagespeed|headlesschrome|prerender|ia_archiver|mediapartners)") {
              set req.http.X-Forem-Redirect-Location = "https://" + var.cd_app_domain + "/__forem_cd_auth_check?domain=" + urlencode(var.cd_req_host) + "&return_to=" + urlencode(req.url);
              error 752;
            }
          }
        }
      }
    }
  }

  # 2. Safely override the Host header only for custom domains.
  # We do NOT touch the host header if it is already dev.to or www.dev.to.
  if (req.http.Host != "dev.to" && req.http.Host != "www.dev.to" && req.http.Host != "practicaldev.herokuapp.com") {
    # Rewrite the Host header to match the Heroku application domain
    set req.http.Host = "practicaldev.herokuapp.com";
  }
}

sub vcl_error {
  if (obj.status == 752) {
    set obj.status = 302;
    set obj.response = "Found";
    set obj.http.Location = req.http.X-Forem-Redirect-Location;
    set obj.http.Cache-Control = "private, no-store, no-cache, must-revalidate";
    set obj.http.Vary = "Cookie";
    set obj.http.Content-Type = "text/html; charset=utf-8";
    synthetic {""};
    return (deliver);
  }
  if (obj.status == 753) {
    set obj.status = 400;
    set obj.response = "Bad Request";
    set obj.http.Cache-Control = "private, no-store, no-cache, must-revalidate";
    set obj.http.Content-Type = "text/plain; charset=utf-8";
    synthetic {"Bad Request"};
    return (deliver);
  }
  if (obj.status == 754) {
    set obj.status = 204;
    set obj.response = "No Content";
    set obj.http.Cache-Control = "private, no-store, no-cache, must-revalidate";
    set obj.http.Vary = "Cookie";
    synthetic {""};
    return (deliver);
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

sub vcl_deliver {
  if (fastly.ff.visits_this_service == 0
      && req.http.X-Forem-Set-Cd-Anon == "1"
      && !req.http.X-Forem-Redirect-Location) {
    add resp.http.Set-Cookie = "cd_anon=1; Path=/; Max-Age=300; HttpOnly; Secure; SameSite=Lax";
  }
}
