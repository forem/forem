require "rails_helper"

RSpec.describe "PodcastOwnershipsDestroy", type: :request do
  let(:user) { create(:user) }
  let(:podcast_ownership) { create(:podcast_ownership, user_id: user.id) }

  before do
    sign_in user
  end

  describe "DELETE /podcast_ownerships/:id" do
    it "destroys the comment" do
      podcast_ownership = create(:podcast_ownership, user_id: user.id)
      expect do
        delete "/podcast_ownerships/#{podcast_ownership.id}"
      end.to change(PodcastOwnership, :count).by(-1)
    end
  end
end
