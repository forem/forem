require "rails_helper"
require "sentry-rails"

RSpec.describe Instrumentation do
  let(:dummy_class) do
    Class.new do
      include Instrumentation
    end
  end

  after do
    Sentry.close if Sentry.initialized?
  end

  it "returns the block value without Datadog when DD_API_KEY is unset" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DD_API_KEY").and_return(nil)

    result = dummy_class.new.__send__(:instrument, "test.op", tags: { user_id: 42 }) { "computed" }

    expect(result).to eq("computed")
  end

  it "traces operations with Datadog when DD_API_KEY is present and returns the block value" do
    require "ddtrace"
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DD_API_KEY").and_return("dd-key")
    allow(Datadog::Tracing).to receive(:trace).and_yield

    result = dummy_class.new.__send__(:instrument, "test.op", tags: { user_id: 42 }) { "computed" }

    expect(result).to eq("computed")
    expect(Datadog::Tracing).to have_received(:trace).with("test.op", tags: { user_id: 42 })
  end

  it "records a child span in Sentry with tag metadata when Sentry is initialized" do
    Sentry.init do |config|
      config.dsn = "https://token@in.logs.betterstack.com/2775219"
      config.traces_sample_rate = 1.0
      config.background_worker_threads = 0
    end

    transaction = Sentry.start_transaction(name: "Stories::FeedsController#show", op: "http.server", sampled: true)
    Sentry.get_current_scope.set_span(transaction)

    result = described_class.instrument(
      "feed.query",
      span_type: "db",
      resource: "Stories::FeedsController.signed_out_base_feed",
      tags: { feed_class: "articles-feeds-weighted" },
    ) { "stories" }

    expect(result).to eq("stories")
    child_span = transaction.span_recorder.spans.last
    expect(child_span.op).to eq("feed.query")
    expect(child_span.description).to eq("Stories::FeedsController.signed_out_base_feed")
    expect(child_span.data).to include("feed_class" => "articles-feeds-weighted")
  ensure
    Sentry.get_current_scope.clear
  end
end
