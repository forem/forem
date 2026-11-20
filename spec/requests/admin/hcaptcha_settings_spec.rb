require "rails_helper"

RSpec.describe "Admin hCaptcha settings" do
  after { Settings::Authentication.clear_cache }

  it "selects hCaptcha and redacts its secret in audit events", :aggregate_failures do
    sign_in create(:user, :super_admin)
    allow(Audit::Logger).to receive(:log).and_call_original
    post admin_settings_authentications_path, params: {
      settings_authentication: {
        captcha_provider: "hcaptcha", hcaptcha_site_key: "hcaptcha-site", hcaptcha_secret_key: "hcaptcha-secret"
      }
    }

    expect(response).to have_http_status(:ok)
    expect(Settings::Authentication.captcha_provider).to eq("hcaptcha")
    expect(Settings::Authentication.hcaptcha_site_key).to eq("hcaptcha-site")
    expect(Settings::Authentication.hcaptcha_secret_key).to eq("hcaptcha-secret")
    expect(Audit::Logger).to have_received(:log).with(
      :internal, anything,
      hash_including("settings_authentication" => hash_including("hcaptcha_secret_key" => "[FILTERED]"))
    )
  end

  it "renders hCaptcha's provider option and key fields" do
    sign_in create(:user, :super_admin)
    get admin_config_path
    expect(response.body).to include('value="hcaptcha"', "settings_authentication[hcaptcha_site_key]",
                                     "settings_authentication[hcaptcha_secret_key]")
  end

  it "filters hCaptcha response tokens" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    expect(filter.filter("h-captcha-response" => "private-response")).to eq("h-captcha-response" => "[FILTERED]")
  end
end
