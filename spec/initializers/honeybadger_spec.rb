require "rails_helper"

RSpec.describe "Honeybadger initializer" do # rubocop:disable RSpec/DescribeClass
  let(:initializer_path) { Rails.root.join("config/initializers/honeybadger.rb") }

  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
  end

  after do
    allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_API_KEY").and_return(nil)
    load initializer_path
  end

  context "when HONEYBADGER_API_KEY is unset" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_API_KEY").and_return(nil)
    end

    it "does not require honeybadger and provides no-op methods when loading the initializer" do
      allow(Kernel).to receive(:require).and_call_original

      load initializer_path

      expect(Kernel).not_to have_received(:require).with("honeybadger")
      expect(Honeybadger.notify(StandardError.new("boom"))).to be(false)
      expect { Honeybadger.context(user_id: 1) }.not_to raise_error
      expect(Honeybadger.context(user_id: 1) { "ok" }).to eq("ok")
      expect { Honeybadger.clear! }.not_to raise_error
      expect { Honeybadger.add_breadcrumb("test") }.not_to raise_error
    end

    it "disables exceptions, breadcrumbs, and reporting without missing-key logs when Honeybadger is loaded" do
      require "honeybadger"
      load initializer_path

      expect(Honeybadger.config.get(:api_key)).to be_nil
      expect(Honeybadger.config.get(:report_data)).to be(false)
      expect(Honeybadger.config.get(:"exceptions.enabled")).to be(false)
      expect(Honeybadger.config.get(:"breadcrumbs.enabled")).to be(false)
      expect(Honeybadger.notify(StandardError.new("boom"))).to be(false)
    end
  end

  context "when HONEYBADGER_API_KEY is present" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("HONEYBADGER_API_KEY").and_return("hb-test-key")
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
      allow(ApplicationConfig).to receive(:[]).with("RELEASE_FOOTPRINT").and_return("rel-456")
      load initializer_path
    end

    {
      "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
      "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
      "PG::QueryCanceled" => "pg_query_canceled"
    }.each do |error_key, fingerprint|
      include_examples "#sets_correct_honeybadger_fingerprint", error_key, fingerprint
    end

    it "configures api_key, env, revision, and ignored exceptions" do
      exceptions_to_ignore = [
        ActiveRecord::QueryCanceled,
        ActiveRecord::RecordNotFound,
        Pundit::NotAuthorizedError,
        RateLimitChecker::LimitReached,
      ]

      expect(Honeybadger.config.get(:api_key)).to eq("hb-test-key")
      expect(Honeybadger.config.get(:env)).to eq("dev.to-test")
      expect(Honeybadger.config.get(:revision)).to eq("rel-456")
      expect(Honeybadger.config.get(:"exceptions.enabled")).to be(true)

      ignored_exceptions = Honeybadger.config.ruby[:"exceptions.ignore"]
      expect(exceptions_to_ignore.all? { |e| ignored_exceptions.include?(e) }).to be(true)
    end

    it "disables breadcrumbs in the test environment to avoid instrumenting every ActiveSupport notification" do
      expect(Honeybadger.config.get(:"breadcrumbs.enabled")).to be(false)
    end

    it "sets fingerprint to internal when error is raised from an internal route" do
      notice = Honeybadger::Notice.new(
        Honeybadger.config, component: "internal/feedback_messages"
      )
      Honeybadger.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq("internal")
    end

    it "ignores SIGHUP SignalException notices" do
      notice = Honeybadger::Notice.new(
        Honeybadger.config, error_class: "SignalException", error_message: "SIGHUP"
      )
      Honeybadger.config.before_notify_hooks.first.call(notice)
      expect(notice.halted?).to be(true)
    end
  end

  describe "HONEYBADGER_JS_API_KEY frontend gating" do
    it "gates the honeybadger-script meta tag and data-honeybadger-key attributes on HONEYBADGER_JS_API_KEY" do
      application_layout = Rails.root.join("app/views/layouts/application.html.erb").read
      admin_layout = Rails.root.join("app/views/layouts/admin.html.erb").read
      base_js_erb = Rails.root.join("app/assets/javascripts/base.js.erb").read

      expect(application_layout.scan('if ApplicationConfig["HONEYBADGER_JS_API_KEY"].present?').size).to eq(2)
      expect(admin_layout).to include('if ApplicationConfig["HONEYBADGER_JS_API_KEY"].present?')
      expect(base_js_erb).to include(
        "if (document.body && document.body.dataset && document.body.dataset.honeybadgerKey)",
      )
    end
  end
end
