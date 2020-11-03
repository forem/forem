require "rails_helper"

RSpec.describe "/admin/tags", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:user)        { create(:user) }
  let(:tag)         { create(:tag) }

  before do
    tag
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

  describe "PATCH /admin/tags/:id/add_tag_moderator" do
    before { sign_in super_admin }

    it "adds the given user as trusted and as a tag moderator" do
      patch add_tag_moderator_admin_tag_path(tag.id), params: { id: tag.id, tag: { user_id: user.id } }
      expect(user.tag_moderator?).to be true
      expect(user.trusted).to be true
    end
  end

  describe "DELETE /admin/tags/:id/remove_tag_moderator" do
    before do
      sign_in super_admin
      user.add_role :trusted
      user.add_role :tag_moderator, tag
    end

    it "removes the tag moderator role from the user" do
      delete remove_tag_moderator_admin_tag_path(tag.id), params: { id: tag.id, tag: { user_id: user.id } }
      expect(user.tag_moderator?).to be false
    end

    it "does not remove the trusted role from the user" do
      delete remove_tag_moderator_admin_tag_path(tag.id), params: { id: tag.id, tag: { user_id: user.id } }
      expect(user.trusted).to be true
    end
  end
end
