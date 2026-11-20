require "rails_helper"

RSpec.describe Settings::Authentication do
  after { described_class.clear_cache }

  it "defaults to reCAPTCHA" do
    expect(described_class.captcha_provider).to eq("recaptcha")
  end

  it "allows Turnstile to be selected" do
    described_class.captcha_provider = "turnstile"
    expect(described_class.captcha_provider).to eq("turnstile")
  end

  it "rejects unknown CAPTCHA providers" do
    expect { described_class.captcha_provider = "unknown" }.to raise_error(ActiveRecord::RecordInvalid)
  end
end
