require "rails_helper"

RSpec.describe "ApiSecretsCreate" do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "POST /users/api_secrets" do
    context "when create succeeds" do
      let(:valid_params) { { description: "My Test 3rd Party App" } }

      it "creates an ApiSecret for the user, flashes the token, redirects back, and allows 300-char descriptions",
         :aggregate_failures do
        expect do
          post "/users/api_secrets", params: { api_secret: valid_params }
        end.to change(user.api_secrets, :count).by(1)

        secret = user.api_secrets.order(:id).last
        expect(secret.description).to eq(valid_params[:description])
        expect(flash[:notice]).to include(secret.secret)
        expect(flash[:error]).to be_nil
        expect(response).to have_http_status(:redirect)

        max_desc = "a" * 300
        expect do
          post "/users/api_secrets", params: { api_secret: { description: max_desc } }
        end.to change(user.api_secrets, :count).by(1)
      end
    end

    context "when create fails" do
      it "does not create the ApiSecret and flashes an error message for invalid descriptions", :aggregate_failures do
        [nil, "", "a" * 301].each do |invalid_description|
          expect do
            post "/users/api_secrets", params: { api_secret: { description: invalid_description } }
          end.not_to change(user.api_secrets, :count)

          expect(flash[:error]).to be_truthy
          expect(flash[:notice]).to be_nil
        end
      end
    end

    context "when user has reached the 10 secret limit" do
      before do
        now = Time.current
        ApiSecret.insert_all!(
          Array.new(10) do |i|
            {
              user_id: user.id,
              description: "Key #{i}",
              secret: "secret_token_#{i}",
              created_at: now,
              updated_at: now
            }
          end,
        )
      end

      it "does not create another ApiSecret and flashes an error about the limit", :aggregate_failures do
        expect do
          post "/users/api_secrets", params: { api_secret: { description: "One more" } }
        end.not_to change(user.api_secrets, :count)

        expect(flash[:error]).to be_present
      end
    end
  end
end
