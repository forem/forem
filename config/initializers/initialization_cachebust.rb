# Trigger cache purges for globally-cached endpoints that could have changed
CacheBuster.bust("/shell_top")
CacheBuster.bust("/shell_bottom")
CacheBuster.bust("/async_info/shell_version")
CacheBuster.bust("/onboarding")

# We will set RELEASE_FOOTPRINT in our Forem Cloud environment, or use HEROKU_SLUG_COMMIT if set (e.g. Heroku env)
ENV["RELEASE_FOOTPRINT"] ||= ENV["HEROKU_SLUG_COMMIT"]
