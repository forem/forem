require "rails_helper"

RSpec.describe "ApiSecretsDestroy" do
  let(:api_secret) { create(:api_secret) }
  let(:user) { api_secret.user }

  before { sign_in user }

  describe "DELETE /users/api_secrets" do
    context "when delete succeeds" do
      it "deletes the ApiSecret for the user" do
        expect do
          delete "/users/api_secrets/#{api_secret.id}"
        end.to change(user.api_secrets, :count).by(-1)
      end

      it "flashes a notice" do
        delete "/users/api_secrets/#{api_secret.id}"
        expect(flash[:notice]).to be_truthy
        expect(flash[:error]).to be_nil
      end

      it "cannot delete a non existing secret" do
        expect do
          delete "/users/api_secrets/9999"
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "cannot delete another user's secret" do
        another_user = create(:user)
        secret = create(:api_secret, user: another_user)

        expect do
          delete "/users/api_secrets/#{secret.id}"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when delete fails" do
      before do
        allow(ApiSecret).to receive(:find).with(api_secret.id.to_s).and_return(api_secret)
        allow(api_secret).to receive(:destroy).and_return(false)
      end

      it "does not delete the ApiSecret" do
        path = "/users/api_secrets/#{api_secret.id}"
        expect { delete path }.not_to change(user.api_secrets, :count)
      end

      it "flashes an error message" do
        delete "/users/api_secrets/#{api_secret.id}"
        expect(flash[:error]).to be_truthy
        expect(flash[:notice]).to be_nil
      end
    end
  end
end
