require "rails_helper"

RSpec.describe "Admin CAPTCHA settings" do
  after { Settings::Authentication.clear_cache }

  let(:settings) do
    { captcha_provider: "turnstile", turnstile_site_key: "turnstile-site", turnstile_secret_key: "turnstile-secret" }
  end

  it "renders the provider selector with the current setting", :aggregate_failures do
    sign_in create(:user, :super_admin)
    allow(Settings::Authentication).to receive(:captcha_provider).and_return("turnstile")
    get admin_config_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('value="turnstile"', 'selected="selected"', "Cloudflare Turnstile")
  end

  it "allows a super admin to select Turnstile and store its keys", :aggregate_failures do
    sign_in create(:user, :super_admin)
    allow(Audit::Logger).to receive(:log).and_call_original
    post admin_settings_authentications_path, params: { settings_authentication: settings }

    expect(response).to have_http_status(:ok)
    expect(Settings::Authentication.captcha_provider).to eq("turnstile")
    expect(Settings::Authentication.turnstile_site_key).to eq("turnstile-site")
    expect(Settings::Authentication.turnstile_secret_key).to eq("turnstile-secret")
    expect(Audit::Logger).to have_received(:log).with(
      :internal, anything,
      hash_including("settings_authentication" => hash_including("turnstile_secret_key" => "[FILTERED]"))
    )
  end

  it "does not let an ordinary admin change the CAPTCHA provider" do
    sign_in create(:user, :admin)

    expect do
      post admin_settings_authentications_path, params: { settings_authentication: settings }
    end.to raise_error(Pundit::NotAuthorizedError)
  end
end
