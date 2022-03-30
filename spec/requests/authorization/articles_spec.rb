require "rails_helper"

RSpec.describe "Articles", type: :request do
  let(:user)          { create(:user) }
  let(:super_admin)   { create(:user, :super_admin) }

  describe "GET /create_post_button" do
    context "when limit post creation to admins is enabled" do
      before do
        FeatureFlag.add("limit_post_creation_to_admins")
        FeatureFlag.enable("limit_post_creation_to_admins")
      end

      after { FeatureFlag.remove("limit_post_creation_to_admins") }

      it "returns the Create Post anchor tag for admins" do
        sign_in super_admin
        get authorization_create_post_button_path
        expect(response.body).to include("Create Post")
      end

      it "raises Pundit::NotAuthorizedError for non admins" do
        sign_in user
        expect { get authorization_create_post_button_path }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when limit post creation to admins is disabled" do
      before do
        FeatureFlag.add("limit_post_creation_to_admins")
        FeatureFlag.disable("limit_post_creation_to_admins")
      end

      after { FeatureFlag.remove("limit_post_creation_to_admins") }

      it "returns a 404", :aggregate_failures do
        sign_in user
        get authorization_create_post_button_path
        expect(response).to have_http_status(:not_found)

        sign_in super_admin
        get authorization_create_post_button_path
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
