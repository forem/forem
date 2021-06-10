require "rails_helper"

describe Honeybadger do
  {
    "SuspendedError" => "banned",
    "Rack::Timeout::RequestTimeoutException" => "rack_timeout",
    "Rack::Timeout::RequestTimeoutError" => "rack_timeout",
    "PG::QueryCanceled" => "pg_query_canceled"
  }.each do |error_key, fingerprint|
    include_examples "#sets_correct_honeybadger_fingerprint", error_key, fingerprint
  end

  context "when configuration is loaded" do
    it "ignores requested exceptions" do
      exceptions_to_ignore = [
        ActiveRecord::QueryCanceled,
        ActiveRecord::RecordNotFound,
        Pundit::NotAuthorizedError,
        RateLimitChecker::LimitReached,
      ]

      ignored_exceptions = described_class.config.ruby[:"exceptions.ignore"]
      expect(exceptions_to_ignore.all? { |e| ignored_exceptions.include?(e) }).to be(true)
    end
  end

  context "when error is raised from an internal route" do
    it "sets fingerprint to internal" do
      notice = Honeybadger::Notice.new(
        described_class.config, component: "internal/feedback_messages"
      )
      described_class.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq("internal")
    end
  end
end
