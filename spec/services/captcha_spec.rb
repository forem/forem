require "rails_helper"

RSpec.describe Captcha do
  let(:context) { instance_double(RegistrationsController, params: params) }
  let(:params) { { "g-recaptcha-response" => "challenge-token" } }

  before do
    allow(Settings::Authentication).to receive_messages(
      captcha_provider: "recaptcha", recaptcha_site_key: "site-key", recaptcha_secret_key: "secret-key",
    )
  end

  it "selects the configured provider" do
    expect(described_class.provider).to eq(Captcha::Providers::Recaptcha)
    allow(Settings::Authentication).to receive(:captcha_provider).and_return("turnstile")
    expect(described_class.provider).to eq(Captcha::Providers::Turnstile)
  end

  it "does not fall back when an unknown provider is configured" do
    allow(Settings::Authentication).to receive(:captcha_provider).and_return("unknown")
    expect { described_class.provider }.to raise_error(KeyError)
  end

  it "retains the legacy eligibility constants as the same shared policy", :aggregate_failures do
    expect(ReCaptcha::CheckEnabled).to eq(Captcha::CheckEnabled)
    expect(ReCaptcha::CheckRegistrationEnabled).to eq(Captcha::CheckRegistrationEnabled)
  end

  it "keeps reCAPTCHA's existing verification helper" do
    allow(context).to receive(:verify_recaptcha).with(secret_key: "secret-key").and_return(true)
    expect(described_class.provider.verify(context: context, action: "signup")).to be(true)
  end

  it "rejects a missing reCAPTCHA response without invoking its verification helper" do
    params.clear
    allow(context).to receive(:verify_recaptcha)
    expect(described_class.provider.verify(context: context, action: "signup")).to be_falsey
    expect(context).not_to have_received(:verify_recaptcha)
  end

  it "disables unconfigured reCAPTCHA but never disables a selected Turnstile provider", :aggregate_failures do
    allow(Settings::Authentication).to receive_messages(recaptcha_site_key: nil, recaptcha_secret_key: nil)
    expect(described_class.provider.enabled?).to be(false)
    allow(Settings::Authentication).to receive_messages(captcha_provider: "turnstile", turnstile_site_key: nil,
                                                        turnstile_secret_key: nil)
    expect(described_class.provider.enabled?).to be(true)
    expect(Captcha::CheckEnabled.call).to be(true)
  end

  it "keeps each provider's presentation behind the shared interface", :aggregate_failures do
    expect(described_class.provider.partial).to eq("shared/captcha/recaptcha")
    expect(described_class.provider.container_class).to eq("recaptcha-tag-container")
    expect(described_class.provider.error_key).to eq("recaptcha")
    expect(described_class.provider.label).to eq("Google reCAPTCHA")
    allow(Settings::Authentication).to receive(:captcha_provider).and_return("turnstile")
    expect(described_class.provider.partial).to eq("shared/captcha/turnstile")
    expect(described_class.provider.container_class).to eq("captcha-tag-container")
    expect(described_class.provider.error_key).to eq("captcha")
    expect(described_class.provider.label).to eq("Cloudflare Turnstile")
  end
end
