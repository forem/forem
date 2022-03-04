require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/support/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.ignore_localhost = true

  # tell VCR to ignore browsers download sites
  # see <https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock>
  config.ignore_hosts(
    "chromedriver.storage.googleapis.com",
    "github.com/mozilla/geckodriver/releases",
    "selenium-release.storage.googleapis.com",
    "developer.microsoft.com/en-us/microsoft-edge/tools/webdriver",
    "api.knapsackpro.com", "localhost", "127.0.0.1", "0.0.0.0"
  )

  # Removes all private data (Basic Auth, Set-Cookie headers...)
  config.before_record do |i|
    # Twitter embeds the Bearer access token in the JSON HTTP response
    if i.request.uri.include?("api.twitter.com/oauth2/token")
      data = JSON.parse(i.response.body)
      data["access_token"] = "ACCESS_TOKEN"
      i.response.body = data.to_json
    end

    i.response.headers.delete("Set-Cookie")
    i.request.headers.delete("Authorization")

    u = URI.parse(i.request.uri)
    i.request.uri.sub!(%r{://.*#{Regexp.escape(u.host)}}, "://#{u.host}")
  end
end
