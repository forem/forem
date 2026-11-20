RSpec.shared_examples "#sets_correct_honeybadger_fingerprint" do |error_key, fingerprint|
  it "sets the #{fingerprint} fingerprint for #{error_key}" do
    notice = Honeybadger::Notice.new(
      Honeybadger.config, error_message: "CRAP! #{error_key} Bail!"
    )
    Honeybadger.config.before_notify_hooks.first.call(notice)
    expect(notice.fingerprint).to eq(fingerprint)
  end
end
