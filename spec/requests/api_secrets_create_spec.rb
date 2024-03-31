require "rails_helper"

RSpec.describe "ApiSecretsCreate" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /users/api_secrets" do
    context "when create succeeds" do
      let(:valid_params) { { description: "My Test 3rd Party App" } }

      it "creates an ApiSecret for the user" do
        expect { post "/users/api_secrets", params: { api_secret: valid_params } }
          .to change { user.api_secrets.count }.by 1
      end

      it "sets the description" do
        post "/users/api_secrets", params: { api_secret: valid_params }
        expect(user.api_secrets.last.description).to eq valid_params[:description]
      end

      it "flashes a message containing the token" do
        post "/users/api_secrets", params: { api_secret: valid_params }
        expect(flash[:notice]).to include(ApiSecret.last.secret)
        expect(flash[:error]).to be_nil
      end
    end

    context "when create fails" do
      let(:invalid_params) { { description: nil } } # Force model validation error

      it "does not create the ApiSecret" do
        expect { post "/users/api_secrets", params: { api_secret: invalid_params } }
          .not_to(change { user.api_secrets.count })
      end

      it "flashes an error message" do
        post "/users/api_secrets", params: { api_secret: invalid_params }
        expect(flash[:error]).to be_truthy
        expect(flash[:notice]).to be_nil
      end
    end
  end
end
