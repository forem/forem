require "rails_helper"

RSpec.describe "/admin/advanced/secrets", type: :request do
  before do
    allow(AppSecrets).to receive(:vault_enabled?).and_return(true)
    allow(AppSecrets).to receive(:[]=)
  end

  context "when the user is not an admin" do
    it "blocks the request" do
      user = create(:user)
      sign_in user

      expect do
        get admin_secrets_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }

    before { sign_in admin }

    describe "GET /admin/advanced/secrets" do
      it "renders with status 200" do
        get admin_secrets_path
        expect(response).to have_http_status :ok
      end

      it "displays an alert when Vault is not enabled" do
        allow(AppSecrets).to receive(:vault_enabled?).and_return(false)
        get admin_secrets_path
        expect(response.body).to include("Vault is not currently setup for your application")
      end
    end

    describe "PUT /admin/advanced/secrets" do
      let(:valid_secret) { AppSecrets::SETTABLE_SECRETS.first }
      let(:valid_params) { { valid_secret => "SECRET_VALUE" } }

      it "successfully sets a secret and shows flash message" do
        allow(AppSecrets).to receive(:[]=)
        put admin_secrets_path, params: valid_params
        expect(response).to have_http_status :found
        expect(AppSecrets).to have_received(:[]=).with(valid_secret, "SECRET_VALUE")
        expect(flash[:success]).to include("Secret #{valid_secret} was successfully updated in Vault")
      end

      it "returns a bad_request with invalid params" do
        put admin_secrets_path, params: {}
        expect(response).to have_http_status :bad_request
      end

      it "creates an audit log" do
        Audit::Subscribe.listen :internal
        expect do
          put admin_secrets_path, params: valid_params
        end.to change(AuditLog, :count).by(1)
        Audit::Subscribe.forget :internal
      end
    end
  end
end
