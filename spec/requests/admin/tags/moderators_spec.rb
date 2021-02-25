require "rails_helper"

RSpec.describe "/admin/tags/:id/moderator", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:user)        { create(:user) }
  let(:tag)         { create(:tag) }

  describe "POST /admin/tags/:id/moderator" do
    before { sign_in super_admin }

    it "adds the given user as trusted and as a tag moderator" do
      post admin_tag_moderator_path(tag.id), params: { tag_id: tag.id, tag: { user_id: user.id } }
      expect(user.tag_moderator?).to be true
      expect(user.trusted).to be true
    end
  end

  describe "DELETE /admin/tags/:id/moderator" do
    before do
      sign_in super_admin
      user.add_role(:trusted)
      user.add_role(:tag_moderator, tag)
    end

    it "removes the tag moderator role from the user" do
      delete admin_tag_moderator_path(tag.id), params: { tag_id: tag.id, tag: { user_id: user.id } }
      expect(user.tag_moderator?).to be false
    end

    it "does not remove the trusted role from the user" do
      delete admin_tag_moderator_path(tag.id), params: { tag_id: tag.id, tag: { user_id: user.id } }
      expect(user.trusted).to be true
    end
  end
end
