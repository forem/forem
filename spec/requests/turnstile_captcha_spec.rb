require "rails_helper"

RSpec.describe "Turnstile CAPTCHA" do
  let(:verification_result) { { success: true, hostname: "forem.test" } }
  let(:registration_params) do
    {
      :user => {
        name: "Test User", username: "captcha_test", email: "captcha@example.com",
        password: "PaSSw0rd_yo000", password_confirmation: "PaSSw0rd_yo000"
      },
      "cf-turnstile-response" => "challenge-token"
    }
  end
  let(:feedback_params) do
    {
      :feedback_message => {
        feedback_type: "abuse-reports", category: "rude or vulgar",
        reported_url: "https://example.com", message: "An abuse report"
      },
      "cf-turnstile-response" => "abuse-token"
    }
  end

  before do
    host! "forem.test"
    allow(Settings::Authentication).to receive_messages(
      captcha_provider: "turnstile", turnstile_site_key: "turnstile-site",
      turnstile_secret_key: "turnstile-secret", recaptcha_site_key: nil, recaptcha_secret_key: nil,
      allow_email_password_registration: true, require_captcha_for_email_password_registration: true
    )
    { "challenge-token" => "signup", "abuse-token" => "abuse_report" }.each do |token, action|
      stub_request(:post, Turnstile::Verify::ENDPOINT)
        .with(body: { secret: "turnstile-secret", response: token })
        .to_return(status: 200, body: verification_result.merge(action: action).to_json)
    end
  end

  it "renders Turnstile rather than reCAPTCHA on signup", :aggregate_failures do
    get sign_up_path, params: { state: "email_signup" }

    expect(response.body).to include('class="cf-turnstile"', 'data-sitekey="turnstile-site"')
    expect(response.body).not_to include("turnstile-secret", "recaptcha-tag-container")
  end

  it "renders Turnstile on abuse reports", :aggregate_failures do
    get "/report-abuse"

    expect(response.body).to include("cf-turnstile", "turnstile-site")
    expect(response.body).not_to include("turnstile-secret", "recaptcha-tag-container")
  end

  it "accepts a registration after server-side verification" do
    expect { post "/users", params: registration_params }.to change(User, :count).by(1)
  end

  it "accepts an abuse report after server-side verification" do
    expect { post feedback_messages_path, params: feedback_params }.to change(FeedbackMessage, :count).by(1)
  end

  context "when verification fails" do
    let(:verification_result) { { :success => false, "error-codes" => ["timeout-or-duplicate"] } }

    it "rejects a registration", :aggregate_failures do
      expect { post "/users", params: registration_params }.not_to change(User, :count)
      expect(response).to redirect_to("/users/sign_up?state=email_signup")
      expect(flash[:notice]).to eq(I18n.t("registrations_controller.error.captcha"))
    end

    it "rejects an abuse report" do
      expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
    end
  end

  context "without a token" do
    it "does not accept a reCAPTCHA token in place of Turnstile" do
      registration_params.delete("cf-turnstile-response")
      registration_params["g-recaptcha-response"] = "challenge-token"

      expect { post "/users", params: registration_params }.not_to change(User, :count)
    end

    it "rejects an abuse report" do
      feedback_params.delete("cf-turnstile-response")
      expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
    end
  end

  context "when Turnstile keys are missing" do
    before { allow(Settings::Authentication).to receive(:turnstile_secret_key).and_return(nil) }

    it "does not disable signup verification" do
      expect { post "/users", params: registration_params }.not_to change(User, :count)
    end

    it "does not disable abuse report verification" do
      expect { post feedback_messages_path, params: feedback_params }.not_to change(FeedbackMessage, :count)
    end
  end

  it "keeps signup CAPTCHA optional when the requirement is off", :aggregate_failures do
    allow(Settings::Authentication).to receive(:require_captcha_for_email_password_registration).and_return(false)
    get sign_up_path, params: { state: "email_signup" }
    expect(response.body).not_to include("cf-turnstile")

    registration_params.delete("cf-turnstile-response")
    expect { post "/users", params: registration_params }.to change(User, :count).by(1)
  end

  it "preserves the trusted-user abuse report exemption" do
    sign_in create(:user, :trusted)
    feedback_params.delete("cf-turnstile-response")

    expect { post feedback_messages_path, params: feedback_params }.to change(FeedbackMessage, :count).by(1)
  end
end
