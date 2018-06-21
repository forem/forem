# controller specs are now discouraged in favor of request specs.
# This file should eventually be removed
require "rails_helper"

RSpec.describe ArticlesController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #feed" do
    it "works" do
      get :feed, format: :rss
      expect(response.status).to eq(200)
    end
  end

  describe "GET #new" do
    before { sign_in user }

    context "with authorized user" do
      it "returns a new article" do
        get :new
        expect(response).to render_template(:new)
      end
    end

    context "with authorized user with tag param" do
      it "returns a new article" do
        get :new, params: { slug: "shecoded" }
        expect(response).to render_template(:new)
      end
    end
  end
end
