require "rails_helper"

RSpec.describe "Homepage", type: :request do
  let(:user) { create(:user) }

  describe "GET /" do
    context "when limit post creation to admins" do
      before { FeatureFlag.add("limit_post_creation_to_admins") }

      after { FeatureFlag.remove("limit_post_creation_to_admins") }

      it "does not render turbo frame when disabled" do
        FeatureFlag.disable("limit_post_creation_to_admins")

        sign_in user
        get root_path

        expect(response.body).not_to include("turbo-frame")
      end

      it "renders turbo frame when enabled" do
        FeatureFlag.enable("limit_post_creation_to_admins")

        sign_in user
        get root_path

        expect(response.body).to include("turbo-frame")
      end
    end
  end
end
