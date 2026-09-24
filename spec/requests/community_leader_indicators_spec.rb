require "rails_helper"

RSpec.describe "Community leader indicators" do
  let(:leader) { create(:user, :community_leader_level_2) }
  let(:article) { create(:article, user: leader) }

  before do
    FeatureFlag.add(:community_favorites)
    FeatureFlag.enable(:community_favorites)
  end

  after { FeatureFlag.remove(:community_favorites) }

  describe "the leader icon" do
    it "renders on the leader's profile" do
      get leader.path

      expect(response.body).to include(%(class="community-leader-icon"))
    end

    it "renders beside the author on an article page" do
      get article.path

      expect(response.body).to include(%(class="community-leader-icon"))
    end

    it "renders beside a leader's comment" do
      comment = create(:comment, commentable: create(:article), user: leader)

      get comment.commentable.path

      expect(response.body).to include(%(class="community-leader-icon"))
    end

    it "does not render for a user who is not a leader" do
      get create(:user).path

      expect(response.body).not_to include(%(class="community-leader-icon"))
    end

    it "does not render when the feature flag is disabled" do
      FeatureFlag.disable(:community_favorites)

      get leader.path

      expect(response.body).not_to include(%(class="community-leader-icon"))
    end
  end

  describe "the favorited marker" do
    let(:author) { create(:user) }
    let(:favorited) { create(:article, user: author) }

    before { favorited.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current) }

    it "renders on a story card for favorited content" do
      get author.path

      expect(response.body).to include(%(class="favorited-marker"))
    end

    it "does not render on a story card nobody has favorited" do
      get create(:article).user.path

      expect(response.body).not_to include(%(class="favorited-marker"))
    end

    it "does not render when the feature flag is disabled" do
      FeatureFlag.disable(:community_favorites)

      get author.path

      expect(response.body).not_to include(%(class="favorited-marker"))
    end
  end
end
