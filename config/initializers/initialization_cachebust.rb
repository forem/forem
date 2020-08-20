# Trigger cache purges for globally-cached endpoints that could have changed
CacheBuster.bust("/shell_top")
CacheBuster.bust("/shell_bottom")
CacheBuster.bust("/async_info/shell_version")
CacheBuster.bust("/onboarding")

# Date/time string ending in minute.
# Used as part of cache key. Minute precision is fine.
# This replaces HEROKU_SLUG_COMMIT everywhere where we don't need exact release-based-precision
# But if anyone has a better way to automate this incrementation in the simplest way that would be consistent
# across all processes 100% of the time, feel free to replace this value :)
ENV["RELEASE_FOOTPRINT"] = Time.current.strftime("%y%m%d%H%M")
