# controller specs are now discouraged in favor of request specs.
# This file should eventually be removed
require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "without current_user" do
      it "returns a 302" do
        get :index, params: { user_board: "following" }
        expect(response.status).to eq(302)
      end
    end

    context "with current_user" do
      before { sign_in user }

      it "works for followings" do
        get :index, params: { user_board: "following" }
        expect(response.status).to eq(200)
      end

      it" works for followers" do
        get :index, params: { user_board: "followers" }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "GET #edit" do
    context "without being signed in" do
      it "returns redirect" do
        get :edit
        expect(response).to redirect_to("/enter")
      end
    end

    context "with authorized user" do
      before { sign_in user }

      it "returns 200" do
        get :edit
        expect(response.status).to eq(200)
      end
    end
  end
end
