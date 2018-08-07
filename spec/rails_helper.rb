# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = "test"

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "webmock/rspec"
require "capybara/rspec"
require "stream_rails"
require "selenium/webdriver"
require "rspec/retry"
require "algolia/webmock"
require "approvals/rspec"
require "shoulda/matchers"
require "pundit/rspec"
require "pundit/matchers"

WebMock.disable_net_connect!(allow_localhost: true)

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  Approvals.configure do |approvals_config|
    approvals_config.approvals_path = "#{::Rails.root}/spec/support/fixtures/approvals/"
  end

  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include RequestSpecHelper, type: :request
  config.include ApplicationHelper
  # config.include CommentsHelper, type: :view

  config.use_transactional_fixtures = false
  config.include FactoryBot::Syntax::Methods

  # Apply rack_session_access integrated with devise.
  config.include Devise::Test::IntegrationHelpers, type: :feature

  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on features
  config.around :each, :js do |ex|
    ex.run_with_retry retry: 3
  end

  config.before do
    ActiveRecord::Base.observers.disable :all # <-- Turn 'em all off!
  end

  # Only turn on VCR if :vcr is included metadata keys
  config.around do |ex|
    if ex.metadata.key?(:vcr)
      ex.run
    else
      VCR.turned_off { ex.run }
    end
  end

  # Allow testing with Stripe's test server. BECAREFUL
  if config.filter_manager.inclusions.rules.include?(:live)
    WebMock.allow_net_connect!
    StripeMock.toggle_live(true)
    puts "Running **live** tests against Stripe..."
  end

  config.before do
    stub_request(:any, /res.cloudinary.com/).to_rack("dsdsdsds")

    stub_request(:post, /api.fastly.com/).
      with(headers: { "Fastly-Key" => "f15066a3abedf47238b08e437684c84f" }).
      to_return(status: 200, body: "", headers: {})

    stub_request(:post, /api.bufferapp.com/).
      to_return(status: 200, body: { fake_text: "so fake" }.to_json, headers: {})

    # stub_request(:any, /api.getstream.io/).to_rack(FakeStream)

    # for twitter image cdn
    stub_request(:get, /twimg.com/).
      to_return(status: 200, body: "", headers: {})

    stub_request(:any, /api.mailchimp.com/).
      to_return(status: 200, body: "", headers: {})

    stub_request(:post, /us-east-api.stream-io-api.com\/api\/v1.0\/feed\/user/).
      to_return(status: 200, body: "{}", headers: {})

    stub_request(:get, /us-east-api.stream-io-api.com\/api/).to_rack(FakeStream)
  end

  # Stub Stream.io
  StreamRails.enabled = false

  # Omniauth mock

  OmniAuth.config.test_mode = true

  raw_info = Hashie::Mash.new
  raw_info.email = "yourname@email.com"
  raw_info.first_name = "fname"
  raw_info.gender = "female"
  raw_info.id = "123456"
  raw_info.last_name = "lname"
  raw_info.link = "http://www.facebook.com/url&#8221"
  raw_info.lang = "fr"
  raw_info.locale = "en_US"
  raw_info.name = "fname lname"
  raw_info.timezone = 5.5
  raw_info.updated_time = "2012-06-08T13:09:47+0000"
  raw_info.username = "fname.lname"
  raw_info.verified = true
  raw_info.followers_count = 100
  raw_info.friends_count = 1000
  raw_info.created_at = "2017-06-08T13:09:47+0000"

  extra_info = Hashie::Mash.new
  extra_info.raw_info = raw_info

  info = OmniAuth::AuthHash::InfoHash.new
  info.first_name = "fname"
  # info.image = "http://graph.facebook.com/123456/picture?type=square&#8221"
  info.last_name = "lname"
  info.location = "location,state,country"
  info.name = "fname lname"
  info.nickname = "fname.lname"
  info.verified = true

  credentials = OmniAuth::AuthHash::InfoHash.new
  credentials.token =  "2735246777-jlOnuFlGlvybuwDJfyrIyESLUEgoo6CffyJCQUO"
  credentials.secret = "o0cu6ACtypMQfLyWhme3Vj99uSds7rjr4szuuTiykSYcN"

  twitter_auth_hash = OmniAuth::AuthHash.new
  twitter_auth_hash.provider = "twitter"
  twitter_auth_hash.uid = "123456"
  twitter_auth_hash.info = info
  twitter_auth_hash.extra = extra_info
  twitter_auth_hash.credentials = credentials

  github_auth_hash = OmniAuth::AuthHash.new
  github_auth_hash.provider = "github"
  github_auth_hash.uid = "1234567"
  github_auth_hash.info = info
  github_auth_hash.extra = extra_info
  github_auth_hash.credentials = credentials

  OmniAuth.config.mock_auth[:twitter] = twitter_auth_hash

  OmniAuth.config.mock_auth[:github] = github_auth_hash

  #########

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu no-sandbox window-size=1400,2000) },
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end

# The current driveres implemented are
# - chrome-helper (:chrome) => Use this for browser-based testing
# - headless-chrome (:headless_chrome) => headless version of chrome-helper

Capybara.javascript_driver = :headless_chrome
