require "rails_helper"

RSpec.describe "/internal/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:tag)         { create(:tag) }

  before do
    tag
    sign_in super_admin
  end

  describe "GET /internal/tags" do
    it "responds with 200 OK" do
      get "/internal/tags"
      expect(response.status).to eq 200
    end
  end

  describe "GET /internal/tags/:id" do
    it "responds with 200 OK" do
      get "/internal/tags/#{tag.id}"
      expect(response.status).to eq 200
    end
  end
end
