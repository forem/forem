# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Enable CORS for API v0 (logging is only activated when debug is enabled)
Rails.application.config.middleware.insert_before(
  0,
  Rack::Cors,
  debug: ENV["DEBUG_CORS"].present?,
  logger: (-> { Rails.logger }),
) do
  allow do
    origins do |source, _env|
      source # echo back the client's `Origin` header instead of using `*`
    end

    # allowed public APIs
    %w[articles comments listings podcast_episodes tags users videos].each do |resource_name|
      # allow read operations, disallow custom headers (eg. api-key) and enable preflight caching
      # NOTE: Chrome caps preflight caching at 2 hours, Firefox at 24 hours
      # see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age#Directives
      resource "/api/#{resource_name}/*", methods: %i[head get options], headers: [], max_age: 2.hours.to_i
    end
  end
end
