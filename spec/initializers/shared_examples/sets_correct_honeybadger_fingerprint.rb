RSpec.shared_examples "#sets_correct_honeybadger_fingerprint" do |error_key, fingerprint|
  it "raises an error" do
    notice = Honeybadger::Notice.new(
      described_class.config, error_message: "CRAP! #{error_key} Bail!"
    )
    described_class.config.before_notify_hooks.first.call(notice)
    expect(notice.fingerprint).to eq(fingerprint)
  end
end
