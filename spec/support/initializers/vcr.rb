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
  )

  # Removes all private data (Basic Auth, Set-Cookie headers...)
  config.before_record do |i|
    i.response.headers.delete("Set-Cookie")
    i.request.headers.delete("Authorization")

    u = URI.parse(i.request.uri)
    i.request.uri.sub!(/:\/\/.*#{Regexp.escape(u.host)}/, "://#{u.host}")
  end
end

VCR_OPTIONS = {
  twitter_fetch_status: {
    cassette_name: "twitter_fetch_status",
    allow_playback_repeats: true
  }
}.freeze
