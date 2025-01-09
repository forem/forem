ENV["RAILS_ENV"] = "test"
# Temporary workaround for Ruby 3.0.6 / CGI udpate
ENV["APP_DOMAIN"] = "forem.test"
require "knapsack_pro"
require "simplecov"
require "simplecov_json_formatter"

if ENV["CI"]
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
end
KnapsackPro::Adapters::RSpecAdapter.bind
KnapsackPro::Hooks::Queue.before_queue do |_queue_id|
  SimpleCov.command_name("rspec_ci_node_#{KnapsackPro::Config::Env.ci_node_index}")
end

TMP_RSPEC_XML_REPORT = "tmp/rspec.xml".freeze
FINAL_RSPEC_XML_REPORT = "tmp/rspec_final_results.xml".freeze

KnapsackPro::Hooks::Queue.after_subset_queue do |_queue_id, _subset_queue_id|
  if File.exist?(TMP_RSPEC_XML_REPORT)
    FileUtils.mv(TMP_RSPEC_XML_REPORT, FINAL_RSPEC_XML_REPORT)
  end
end

require "spec_helper"

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
abort("The Rails environment is running in production mode!") if Rails.env.production?

Rake.application = Rake::Application.new
Rails.application.load_tasks

# Add additional requires below this line. Rails is not loaded until this point!

require "fakeredis/rspec"
require "pundit/matchers"
require "pundit/rspec"
require "sidekiq/testing"
require "test_prof/factory_prof/nate_heckler"
require "validate_url/rspec_matcher"
require "webmock/rspec"

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

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/system/shared_examples/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/models/shared_examples/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/workers/shared_examples/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/initializers/shared_examples/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/mailers/shared_examples/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/policies/shared_examples/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Disable internet connection with Webmock
# allow browser websites, so that "webdrivers" can access their binaries
# see <https://github.com/titusfortner/webdrivers/wiki/Using-with-VCR-or-WebMock>
allowed_sites = [
  "chromedriver.storage.googleapis.com",
  "github.com/mozilla/geckodriver/releases",
  "selenium-release.storage.googleapis.com",
  "developer.microsoft.com/en-us/microsoft-edge/tools/webdriver",
  "api.knapsackpro.com",
  ENV.fetch("CHROME_URL", nil),
]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_sites)

RSpec::Matchers.define_negated_matcher :not_change, :change

Rack::Attack.enabled = false

# `browser`, a dependency of `field_test`, starting from version 3.0
# considers the empty user agent a bot, which will fail tests as we
# explicitly configure field tests to exclude bots
# see https://github.com/fnando/browser/blob/master/CHANGELOG.md#300
Browser::Bot.matchers.delete(Browser::Bot::EmptyUserAgentMatcher)

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.fixture_path = Rails.root.join("spec/fixtures")

  config.include ActionMailer::TestHelper
  config.include ApplicationHelper
  config.include CommentsHelpers
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include EmbedsHelpers, type: :liquid_tag
  config.include FactoryBot::Syntax::Methods
  config.include OmniauthHelpers
  config.include RpushHelpers
  config.include SidekiqTestHelpers

  config.extend WithModel

  config.after(:each, type: :system) do
    Warden::Manager._on_request.clear
  end

  config.after(:each, type: :request) do
    Warden::Manager._on_request.clear
  end

  config.around do |example|
    case example.metadata[:sidekiq]
    when :inline
      Sidekiq::Testing.inline! { example.run }
    when :fake
      Sidekiq::Testing.fake! { example.run }
    when :disable
      Sidekiq::Testing.disable! { example.run }
    else
      example.run
    end
  end

  config.before(:each, :algolia) do
    allow(Settings::General).to receive_messages(
      algolia_application_id: "on", algolia_search_only_api_key: "on", algolia_api_key: "on",
    )
  end

  config.before(:suite) do
    # Set the TZ ENV variable with the current random timezone from zonebie
    # which we can then use to properly set the browser time for Capybara specs
    ENV["TZ"] = Time.zone.tzinfo.name
  end

  config.before do
    # Worker jobs shouldn't linger around between tests
    Sidekiq::Job.clear_all
    # Disable SSRF protection for CarrierWave specs
    # See: https://github.com/carrierwaveuploader/carrierwave/issues/2531
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(CarrierWave::Downloader::Base)
      .to receive(:skip_ssrf_protection?).and_return(true)
    # rubocop:enable RSpec/AnyInstance
    # Doing this via a stub gets rid of the following error:
    # "Please stub a default value first if message might be received with other args as well."
    allow(FeatureFlag).to receive(:enabled?).and_call_original
    allow(FeatureFlag).to receive(:enabled?).with(:connect).and_return(true)
  end

  config.around(:each, :flaky) do |ex|
    ex.run_with_retry retry: 5
  end

  config.around(:each, :throttle) do |example|
    Rack::Attack.enabled = true
    example.run
    Rack::Attack.enabled = false
  end

  config.after do
    Settings::General.clear_cache
  end

  # Only turn on VCR if :vcr is included metadata keys
  config.around do |ex|
    if ex.metadata.key?(:vcr)
      ex.run
    else
      VCR.turned_off { ex.run }
    end
  end

  # [@jeremyf] <2022-02-07 Mon> :: In https://github.com/forem/forem/pull/16423 we were discussing
  #
  # There are three use cases to consider regarding the Listing feature:
  #
  # - Those who will have it enabled (e.g., DEV.to), if they so choose to enable the flag.
  # - Those who will not have it enabled (e.g., those that do nothing)
  # - Our test suite
  #
  # We want our test suite to behave as though it's enabled by default.  This rspec configuration
  # helps with that.  I envision this to be a placeholder.  But we need something to get the RFC out
  # the door (https://github.com/forem/rfcs/issues/291).
  config.before do
    allow(Listing).to receive(:feature_enabled?).and_return(true)
  end

  config.before do
    stub_request(:any, /res.cloudinary.com/).to_rack("dsdsdsds")

    stub_request(:any, /emojipedia-us.s3.dualstack.us-west-1.amazonaws.com/).to_rack("stubbed-emoji")

    stub_request(:post, /api.fastly.com/)
      .to_return(status: 200, body: "".to_json, headers: {})

    stub_request(:any, /localhost:9090/)
      .to_return(status: 200, body: "OK".to_json, headers: {})

    # for twitter image cdn
    stub_request(:get, /twimg.com/)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:any, /api.mailchimp.com/)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:any, /dummyimage.com/)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:post, "http://www.google-analytics.com/collect")
      .to_return(status: 200, body: "", headers: {})

    stub_request(:post, /insights.algolia.io/)
      .to_return(status: 200, body: "", headers: {})

    stub_request(:any, /robohash.org/)
      .with(headers:
            {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "Ruby"
            }).to_return(status: 200, body: "", headers: {})
    stub_request(:get, %r{assets/icon})
      .with(headers:
            {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "User-Agent" => "Ruby"
            }).to_return(status: 200, body: "", headers: {})
    stub_request(:get, %r{assets/\d+(-\w+)?\.png})
      .to_return(status: 200, body: "", headers: {})

    allow(Settings::Community).to receive(:community_description).and_return("Some description")
    allow(Settings::UserExperience).to receive(:public).and_return(true)
    allow(Settings::General).to receive(:waiting_on_first_user).and_return(false)

    # Default to have field a field test available.
    if AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT.blank?
      config = { "experiments" =>
                { "wut" =>
                 { "start_date" => 30.days.ago,
                   "variants" => %w[base var_1],
                   "weights" => [50, 50],
                   "goals" => %w[user_creates_comment
                                 user_creates_comment_four_days_in_week
                                 user_views_article_four_days_in_week
                                 user_views_article_four_hours_in_day
                                 user_views_article_nine_days_in_two_week
                                 user_views_article_twelve_hours_in_five_days
                                 user_publishes_post
                                 user_publishes_post_at_least_two_times_within_week
                                 user_publishes_post_at_least_two_times_within_two_weeks] } },
                 "exclude" => { "bots" => true },
                 "cache" => true,
                 "cookies" => false }

      begin
        # Add the field tests that are currently configured (if any).
        field_tests = Psych.load_file("config/field_test.yml")
        config["experiments"].merge!(field_tests.fetch("experiments", {}))
      rescue StandardError
        # Accept that we may not have experiments.
      end
      allow(FieldTest).to receive(:config).and_return(config)
    end
  end

  config.after do
    Timecop.return
  end

  config.after(:suite) do
    WebMock.disable_net_connect!(
      allow_localhost: true,
      allow: allowed_sites,
    )
  end

  OmniAuth.config.test_mode = true
  OmniAuth.config.logger = Rails.logger

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
