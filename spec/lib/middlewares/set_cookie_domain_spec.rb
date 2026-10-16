require "rails_helper"

RSpec.describe Middlewares::SetCookieDomain do
  let(:app) { ->(_env) { [200, {}, ["OK"]] } }
  let(:middleware) { described_class.new(app) }
  let(:env) { { "rack.session.options" => {} } }

  before { RequestStore.clear! }
  after { RequestStore.clear! }

  it "sets the session cookie domain to the root of the app domain" do
    allow(Settings::General).to receive(:app_domain).and_return("www.example.com")

    middleware.call(env)

    expect(env["rack.session.options"][:domain]).to eq(".example.com")
  end

  # This middleware runs before Middlewares::SetSubforem, so there is no subforem context yet.
  # It must keep reading the global app_domain even when the default subforem has its own row.
  it "keeps using the global app_domain when the default subforem has a different one" do
    default_subforem = create(:subforem)
    Settings::General.set_app_domain("global-root.com", subforem_id: nil)
    Settings::General.set_app_domain("default-root.org", subforem_id: default_subforem.id)
    RequestStore.clear!

    middleware.call(env)

    expect(env["rack.session.options"][:domain]).to eq(".global-root.com")
  end
end
