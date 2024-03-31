# http://localhost:3000/rating_votes
require "rails_helper"

RSpec.describe "RatingVotes" do
  let(:user) { create(:user, :trusted) }
  let(:article) { create(:article) }

  before do
    sign_in user
  end

  describe "POST /rating_votes" do
    it "creates a new rating vote" do
      post "/rating_votes", params: {
        rating_vote: {
          article_id: article.id, group: "experience_level", rating: 3.0
        }
      }
      expect(RatingVote.last.rating).to eq(3.0)
      expect(RatingVote.last.user_id).to eq(user.id)
    end

    it "does not create new rating vote for non-trusted user" do
      user.remove_role(:trusted)
      post "/rating_votes", params: {
        rating_vote: {
          article_id: article.id, group: "experience_level", rating: 3.0
        }
      }
      expect(RatingVote.all.size).to eq(0)
    end
  end
end
