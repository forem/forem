require "rails_helper"

RSpec.describe "ApiSecretsDestroy", type: :request do
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  before { sign_in user }

  describe "DELETE /users/api_secrets" do
    context "when delete succeeds" do
      it "deletes the ApiSecret for the user" do
        expect { delete "/users/api_secrets", params: { id: api_secret.id } }.
          to change { user.api_secrets.count }.by -1
      end

      it "flashes a notice" do
        delete "/users/api_secrets", params: { id: api_secret.id }
        expect(flash[:notice]).to be_truthy
        expect(flash[:error]).to be_nil
      end
    end

    context "when delete fails" do
      before do
        allow(ApiSecret).to receive(:find_by_id).and_return api_secret
        allow(api_secret).to receive(:destroy).and_return false
      end

      it "does not delete the ApiSecret" do
        expect { delete "/users/api_secrets", params: { id: api_secret.id } }.
          not_to (change { user.api_secrets.count })
      end

      it "flashes an error message" do
        delete "/users/api_secrets", params: { id: api_secret.id }
        expect(flash[:error]).to be_truthy
        expect(flash[:notice]).to be_nil
      end
    end
  end
end
