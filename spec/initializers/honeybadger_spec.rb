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
end
