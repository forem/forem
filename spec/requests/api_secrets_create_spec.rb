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

      it "redirects back" do
        post "/users/api_secrets", params: { api_secret: valid_params }
        expect(response).to have_http_status(:redirect)
      end

      it "creates a secret with description at maximum length (300 chars)" do
        max_desc = "a" * 300
        expect { post "/users/api_secrets", params: { api_secret: { description: max_desc } } }
          .to change { user.api_secrets.count }.by(1)
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

      it "does not create with an empty string description" do
        expect { post "/users/api_secrets", params: { api_secret: { description: "" } } }
          .not_to(change { user.api_secrets.count })
      end

      it "does not create with description exceeding 300 characters" do
        long_desc = "a" * 301
        expect { post "/users/api_secrets", params: { api_secret: { description: long_desc } } }
          .not_to(change { user.api_secrets.count })
      end
    end

    context "when user has reached the 10 secret limit" do
      before { create_list(:api_secret, 10, user: user) }

      it "does not create another ApiSecret" do
        expect { post "/users/api_secrets", params: { api_secret: { description: "One more" } } }
          .not_to(change { user.api_secrets.count })
      end

      it "flashes an error about the limit" do
        post "/users/api_secrets", params: { api_secret: { description: "One more" } }
        expect(flash[:error]).to be_present
      end
    end
  end
end
