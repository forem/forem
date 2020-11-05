require "rails_helper"

RSpec.describe "/admin/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:user)        { create(:user) }
  let!(:tag) { create(:tag) }

  before do
    sign_in super_admin
  end

  describe "GET /admin/tags" do
    it "responds with 200 OK" do
      get admin_tags_path
      expect(response.status).to eq 200
    end
  end

  describe "GET /admin/tags/:id" do
    it "responds with 200 OK" do
      get admin_tag_path(tag.id)
      expect(response.status).to eq 200
    end
  end
end
