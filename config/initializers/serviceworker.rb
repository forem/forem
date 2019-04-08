Rails.application.configure do
  config.serviceworker.routes.draw do
    # map to assets implicitly
    match "/serviceworker.js",
          headers: { "Cache-Control" => "public, max-age=8000, s-max-age=20000, no-cache" }
    match "/manifest.json",
          headers: { "Cache-Control" => "public, max-age=8000, s-max-age=20000, no-cache" }
    # Examples
    #
    # map to a named asset explicitly
    # match "/proxied-serviceworker.js" => "nested/asset/serviceworker.js"
    # match "/nested/serviceworker.js" => "another/serviceworker.js"
    #
    # capture named path segments and interpolate to asset name
    # match "/captures/*segments/serviceworker.js" => "%{segments}/serviceworker.js"
    #
    # capture named parameter and interpolate to asset name
    # match "/parameter/:id/serviceworker.js" => "project/%{id}/serviceworker.js"
    #
    # insert custom headers
    # match "/header-serviceworker.js" => "another/serviceworker.js",
    #   headers: { "X-Resource-Header" => "A resource" }
    #
    # anonymous glob exposes `paths` variable for interpolation
    # match "/*/serviceworker.js" => "%{paths}/serviceworker.js"
  end
  config.serviceworker.headers["Surrogate-Control"] = "max-age=20000"
  config.serviceworker.headers["Cache-Control"] = "public, s-maxage=20000, max-age=0, no-cache"
end
