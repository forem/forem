require "rails_helper"

RSpec.describe "ApiSecretsCreate" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /users/api_secrets" do
    context "when create succeeds" do
      let(:valid_params) { { description: "My Test 3rd Party App" } }

      it "creates an ApiSecret for the user, flashes the token, and redirects back", :aggregate_failures do
        expect do
          post "/users/api_secrets", params: { api_secret: valid_params }
        end.to change(user.api_secrets, :count).by(1)

        secret = user.api_secrets.last
        expect(secret.description).to eq(valid_params[:description])
        expect(flash[:notice]).to include(secret.secret)
        expect(flash[:error]).to be_nil
        expect(response).to have_http_status(:redirect)
      end

      it "creates a secret with description at maximum length (300 chars)" do
        max_desc = "a" * 300
        expect { post "/users/api_secrets", params: { api_secret: { description: max_desc } } }
          .to change(user.api_secrets, :count).by(1)
      end
    end

    context "when create fails" do
      let(:invalid_params) { { description: nil } } # Force model validation error

      it "does not create the ApiSecret and flashes an error message", :aggregate_failures do
        expect do
          post "/users/api_secrets", params: { api_secret: invalid_params }
        end.not_to change(user.api_secrets, :count)

        expect(flash[:error]).to be_truthy
        expect(flash[:notice]).to be_nil
      end

      it "does not create with an empty string description" do
        expect { post "/users/api_secrets", params: { api_secret: { description: "" } } }
          .not_to change(user.api_secrets, :count)
      end

      it "does not create with description exceeding 300 characters" do
        long_desc = "a" * 301
        expect { post "/users/api_secrets", params: { api_secret: { description: long_desc } } }
          .not_to change(user.api_secrets, :count)
      end
    end

    context "when user has reached the 10 secret limit" do
      before { create_list(:api_secret, 10, user: user) }

      it "does not create another ApiSecret and flashes an error about the limit", :aggregate_failures do
        expect do
          post "/users/api_secrets", params: { api_secret: { description: "One more" } }
        end.not_to change(user.api_secrets, :count)

        expect(flash[:error]).to be_present
      end
    end
  end
end
