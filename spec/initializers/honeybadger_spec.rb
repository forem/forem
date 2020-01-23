require "rails_helper"

describe Honeybadger do
  context "when a fetch_all_rss SIGTERM error is raised" do
    it "sets fingerprint to error_message" do
      notice = Honeybadger::Notice.new(
        described_class.config, error_message: "SignalException: SIGTERM", component: "rake fetch_all_rss"
      )
      described_class.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq(notice.error_message)
    end
  end

  context "when BANNED error is raised" do
    it "sets fingerprint to banned" do
      notice = Honeybadger::Notice.new(
        described_class.config, error_message: "RuntimeError: BANNED"
      )
      described_class.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq("banned")
    end
  end

  context "when Rack::Timeout::RequestTimeoutException is raised" do
    it "sets fingerprint to rack_timeout" do
      notice = Honeybadger::Notice.new(
        described_class.config, error_message: "Rack::Timeout::RequestTimeoutException happened"
      )
      described_class.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq("rack_timeout")
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

  context "when a PG::QueryCanceled error is raised" do
    it "sets fingerprint to pg_query_cancel" do
      notice = Honeybadger::Notice.new(
        described_class.config, error_message: "ActionView::Template::Error: PG::QueryCanceled:"
      )
      described_class.config.before_notify_hooks.first.call(notice)
      expect(notice.fingerprint).to eq("pg_query_canceled")
    end
  end
end
