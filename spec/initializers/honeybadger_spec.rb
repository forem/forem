require "rails_helper"

describe Honeybadger do
  MESSAGE_FINGERPRINTS.each do |error_key, fingerprint|
    include_examples "#sets_correct_honeybadger_fingerprint", error_key, fingerprint
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
