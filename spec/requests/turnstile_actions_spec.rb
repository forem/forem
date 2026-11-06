require "rails_helper"

RSpec.describe "Turnstile form actions" do
  before do
    host! "forem.test"
    allow(Settings::Authentication).to receive_messages(
      captcha_provider: "turnstile", turnstile_site_key: "site-key", turnstile_secret_key: "secret-key",
      allow_email_password_registration: true, require_captcha_for_email_password_registration: true
    )
    stub_request(:post, Turnstile::Verify::ENDPOINT)
      .to_return(body: { success: true, hostname: "forem.test", action: "signup" }.to_json)
  end

  it "renders an explicit signup action" do
    get sign_up_path, params: { state: "email_signup" }
    expect(response.body).to include('data-action="signup"')
  end

  it "renders an explicit abuse-report action" do
    get "/report-abuse"
    expect(response.body).to include('data-action="abuse_report"')
  end

  it "rejects a signup token on the abuse-report endpoint and preserves the report", :aggregate_failures do
    params = {
      :feedback_message => {
        feedback_type: "abuse-reports", category: "spam", reported_url: "https://example.com",
        message: "Report text to preserve"
      },
      "cf-turnstile-response" => "signup-token"
    }

    expect { post feedback_messages_path, params: params }.not_to change(FeedbackMessage, :count)
    expect(response.body).to include("Report text to preserve", 'data-action="abuse_report"')
  end
end
