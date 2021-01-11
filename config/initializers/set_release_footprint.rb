# We will set RELEASE_FOOTPRINT in our Forem Cloud environment, or use HEROKU_SLUG_COMMIT if set (e.g. Heroku env)
ENV["RELEASE_FOOTPRINT"] ||= ENV["HEROKU_RELEASE_CREATED_AT"]
