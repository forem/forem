require "rails_helper"

RSpec.describe "hCaptcha protection" do
  let(:verification_result) { { success: true } }
  let(:registration_params) do
    {
      :user => {
        name: "Test User", username: "hcaptcha_test", email: "hcaptcha@example.com",
        password: "PaSSw0rd_yo000", password_confirmation: "PaSSw0rd_yo000"
      },
      "h-captcha-response" => "challenge-token"
    }
  end
  let(:feedback_params) do
    {
      :feedback_message => {
        feedback_type: "abuse-reports", category: "spam", reported_url: "https://example.com",
        message: "Report text to preserve"
      },
      "h-captcha-response" => "challenge-token"
    }
  end

  before do
    host! "forem.test"
    allow(Settings::Authentication).to receive_messages(
      captcha_provider: "hcaptcha", hcaptcha_site_key: "hcaptcha-site", hcaptcha_secret_key: "hcaptcha-secret",
      recaptcha_site_key: nil, recaptcha_secret_key: nil,
      allow_email_password_registration: true, require_captcha_for_email_password_registration: true
    )
    stub_request(:post, "https://api.hcaptcha.com/siteverify")
      .with(body: { secret: "hcaptcha-secret", response: "challenge-token", sitekey: "hcaptcha-site" })
      .to_return(body: verification_result.to_json)
  end

  it "renders the visible provider without exposing its secret on signup", :aggregate_failures do
    get sign_up_path, params: { state: "email_signup" }
    expect(response.body).to include('class="h-captcha"', 'data-sitekey="hcaptcha-site"')
    expect(response.body).not_to include("hcaptcha-secret", "cf-turnstile", "recaptcha-tag-container")
  end

  it "renders the provider on abuse reports", :aggregate_failures do
    get "/report-abuse"
    expect(response.body).to include('class="h-captcha"', 'data-sitekey="hcaptcha-site"')
    expect(response.body).not_to include("hcaptcha-secret")
  end

  it "accepts verified signups" do
    expect { post "/users", params: registration_params }.to change(User, :count).by(1)
  end

  it "accepts verified reports" do
    expect { post feedback_messages_path, params: feedback_params }.to change(FeedbackMessage, :count).by(1)
  end

  it "does not substitute another provider's token" do
    registration_params.delete("h-captcha-response")
    registration_params["g-recaptcha-response"] = "another-token"
    registration_params["cf-turnstile-response"] = "another-token"
    expect { post "/users", params: registration_params }.not_to change(User, :count)
  end

  %w[invalid-input-response expired-input-response already-seen-response sitekey-secret-mismatch].each do |error|
    context "when hCaptcha returns #{error}" do
      let(:verification_result) { { :success => false, "error-codes" => [error] } }

      it "rejects signup" do
        expect { post "/users", params: registration_params }.not_to change(User, :count)
      end

      it "rejects the report without losing its text", :aggregate_failures do
        expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
        expect(response.body).to include("Report text to preserve", 'class="h-captcha"')
      end
    end
  end

  context "without a configured secret" do
    before { allow(Settings::Authentication).to receive(:hcaptcha_secret_key).and_return(nil) }

    it "does not disable signup verification" do
      expect { post "/users", params: registration_params }.not_to change(User, :count)
    end

    it "does not disable report verification" do
      expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
    end
  end

  it "preserves trusted-user report exemptions" do
    sign_in create(:user, :trusted)
    feedback_params.delete("h-captcha-response")
    expect { post feedback_messages_path, params: feedback_params }.to change(FeedbackMessage, :count).by(1)
  end

  it "keeps signup verification optional without disabling report protection", :aggregate_failures do
    allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(false)
    registration_params.delete("h-captcha-response")
    expect { post "/users", params: registration_params }.to change(User, :count).by(1)
    feedback_params.delete("h-captcha-response")
    expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
  end
end
