require "rails_helper"

RSpec.describe "ApiSecretsDestroy" do
  let(:user) { create(:user) }
  let(:api_secret) { create(:api_secret, user: user) }

  describe "DELETE /users/api_secrets" do
    context "when delete succeeds" do
      before { sign_in user }

      it "deletes the ApiSecret for the user, flashes a notice, and redirects back", :aggregate_failures do
        api_secret
        expect do
          delete "/users/api_secrets/#{api_secret.id}"
        end.to change(user.api_secrets, :count).by(-1)

        expect(flash[:notice]).to be_truthy
        expect(flash[:error]).to be_nil
        expect(response).to have_http_status(:redirect)
      end

      it "cannot delete a non existing secret or another user's secret", :aggregate_failures do
        expect do
          delete "/users/api_secrets/9999"
        end.to raise_error(ActiveRecord::RecordNotFound)

        secret = create(:api_secret)
        expect do
          delete "/users/api_secrets/#{secret.id}"
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when delete fails" do
      before do
        sign_in user
        allow(ApiSecret).to receive(:find).with(api_secret.id.to_s).and_return(api_secret)
        allow(api_secret).to receive(:destroy).and_return(false)
      end

      it "does not delete the ApiSecret and flashes an error message", :aggregate_failures do
        expect do
          delete "/users/api_secrets/#{api_secret.id}"
        end.not_to change(user.api_secrets, :count)

        expect(flash[:error]).to be_truthy
        expect(flash[:notice]).to be_nil
      end
    end

    context "when user is suspended", :proper_status do
      let(:suspended_user) { create(:user, :suspended) }
      let(:owned_secret) { create(:api_secret, user: suspended_user) }

      before do
        sign_in suspended_user
      end

      # destroy? checks user_owner?, not spam_or_suspended? —
      # suspended users should still be able to revoke their own keys.
      it "allows suspended user to delete their own secret" do
        owned_secret # ensure created
        expect do
          delete "/users/api_secrets/#{owned_secret.id}"
        end.to change(suspended_user.api_secrets, :count).by(-1)
      end
    end

    context "when user has spam role", :proper_status do
      let(:spam_user) { create(:user, :spam) }
      let(:owned_secret) { create(:api_secret, user: spam_user) }

      before do
        sign_in spam_user
      end

      # destroy? checks user_owner?, not spam_or_suspended?
      it "allows spam user to delete their own secret" do
        owned_secret # ensure created
        expect do
          delete "/users/api_secrets/#{owned_secret.id}"
        end.to change(spam_user.api_secrets, :count).by(-1)
      end
    end
  end
end
