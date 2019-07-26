require "rails_helper"

RSpec.describe "/internal/podcasts", type: :request do
  describe "PUT /internal/podcasts/:id" do
    let(:admin) { create(:user, :super_admin) }
    let(:podcast) { create(:podcast) }
    let(:user) { create(:user) }

    before do
      sign_in admin
    end

    it "adds an admin" do
      expect do
        post add_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id } }
      end.to change(Role, :count).by(1)
      user.reload
      expect(user.has_role?(:podcast_admin, podcast)).to be true
    end

    it "does nothing when adding an admin for non-existent user" do
      post add_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id + 1 } }
      expect(response).to redirect_to(edit_internal_podcast_path(podcast))
    end

    it "removes an admin" do
      user.add_role(:podcast_admin, podcast)
      expect do
        delete remove_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id } }
      end.to change(Role, :count).by(-1)
      expect(user.has_role?(:podcast_admin, podcast)).to be false
    end

    it "does nothing when removing an admin for non-existent user" do
      delete remove_admin_internal_podcast_path(podcast.id), params: { podcast: { user_id: user.id + 1 } }
      expect(response).to redirect_to(edit_internal_podcast_path(podcast))
    end
  end
end
