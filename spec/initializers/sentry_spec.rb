require "rails_helper"
require "sentry-rails"
require "sentry-sidekiq"

RSpec.describe "Sentry (Better Stack errors & tracing) initializer" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { Rails.root.join("config/initializers/sentry.rb") }
  let(:dsn) { "https://token@in.logs.betterstack.com/2775219" }

  before do
    allow(Rails.env).to receive(:production?).and_return(true)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BETTER_STACK_ERRORS_DSN").and_return(dsn)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BETTER_STACK_ERRORS_DSN").and_return(dsn)
    allow(ENV).to receive(:fetch).with("SENTRY_ENVIRONMENT", Rails.env).and_return("production")
    allow(ENV).to receive(:fetch).with("SENTRY_TRACES_SAMPLE_RATE", "0.05").and_return("1.0")
    allow(Rails.error).to receive(:subscribe)
  end

  after do
    Sentry::Rails::Tracing.unsubscribe_tracing_events
    Sentry::Rails::Tracing.remove_active_support_notifications_patch
    Sentry.close if Sentry.initialized?
  end

  def activate_tracing!
    load initializer_path
    Sentry.configuration.background_worker_threads = 0
    Sentry::Rails::Tracing.register_subscribers(Sentry.configuration.rails.tracing_subscribers)
    Sentry::Rails::Tracing.subscribe_tracing_events
    Sentry::Rails::Tracing.patch_active_support_notifications
  end

  def record_spans
    transaction = Sentry.start_transaction(name: "StoriesController#show", op: "http.server", sampled: true)
    Sentry.get_current_scope.set_span(transaction)
    yield
    transaction.span_recorder.spans.reject { |span| span == transaction }
  ensure
    Sentry.get_current_scope.clear
  end

  it "enables faraday and excon HTTP client patches" do
    load initializer_path

    expect(Sentry.configuration.enabled_patches).to include(:faraday, :excon, :redis, :puma, :http)
  end

  it "traces partial (>= 1ms) and collection rendering in addition to templates" do
    activate_tracing!

    spans = record_spans do
      ActiveSupport::Notifications.instrument("render_template.action_view", identifier: "articles/show.html.erb")
      ActiveSupport::Notifications.instrument("render_partial.action_view", identifier: "articles/_tiny_icon.html.erb")
      ActiveSupport::Notifications.instrument("render_partial.action_view", identifier: "articles/_reaction.erb") do
        sleep(0.002)
      end
      ActiveSupport::Notifications.instrument(
        "render_collection.action_view",
        identifier: "comments/_comment.html.erb",
        count: 42,
        cache_hits: 10,
      )
    end

    expect(spans.map(&:op)).to eq(
      %w[
        template.render_template.action_view
        template.render_partial.action_view
        template.render_collection.action_view
      ],
    )
    expect(spans.map(&:description)).to eq(
      %w[
        articles/show.html.erb
        articles/_reaction.erb
        comments/_comment.html.erb
      ],
    )
    collection_span = spans.last
    expect(collection_span.data).to include("template.count" => 42, "template.cache_hits" => 10)
  end

  it "records distributed cache spans (including read_multi) and skips in-memory stores" do
    activate_tracing!

    spans = record_spans do
      ActiveSupport::Notifications.instrument(
        "cache_read.active_support",
        key: "mem-key",
        store: "ActiveSupport::Cache::MemoryStore",
        hit: true,
      )
      ActiveSupport::Notifications.instrument(
        "cache_read.active_support",
        key: "local-key",
        store: "ActiveSupport::Cache::Strategy::LocalCache::LocalStore",
        hit: true,
      )
      ActiveSupport::Notifications.instrument(
        "cache_read.active_support",
        key: "redis-key",
        store: "ActiveSupport::Cache::RedisCacheStore",
        hit: true,
      )
      ActiveSupport::Notifications.instrument(
        "cache_read_multi.active_support",
        key: %w[k1 k2],
        store: "ActiveSupport::Cache::RedisCacheStore",
        hit: false,
      )
    end

    expect(spans.map(&:op)).to eq(%w[cache.get cache.get])
    expect(spans.map(&:description)).to all(eq("ActiveSupport::Cache::RedisCacheStore"))
    expect(spans.first.data).to include("cache.key" => ["redis-key"], "cache.hit" => true)
    expect(spans.last.data).to include("cache.key" => %w[k1 k2], "cache.hit" => false)
  end

  it "does nothing without BETTER_STACK_ERRORS_DSN" do
    allow(ENV).to receive(:[]).with("BETTER_STACK_ERRORS_DSN").and_return(nil)

    load initializer_path

    expect(Sentry).not_to be_initialized
  end
end
