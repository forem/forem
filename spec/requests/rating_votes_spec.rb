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

    it "creates an explicit rating vote even when a readinglist_reaction vote already exists" do
      create(:rating_vote, user: user, article: article, context: "readinglist_reaction", rating: 5.0)

      expect do
        post "/rating_votes", params: {
          rating_vote: {
            article_id: article.id, group: "experience_level", rating: 8.0
          }
        }, as: :json
      end.to change(RatingVote, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(RatingVote.find_by(user: user, article: article, context: "explicit").rating).to eq(8.0)
      expect(RatingVote.find_by(user: user, article: article, context: "readinglist_reaction").rating).to eq(5.0)
    end

    it "recovers from a concurrent ActiveRecord::RecordNotUnique race by updating the existing vote" do
      existing_vote = create(:rating_vote, user: user, article: article, context: "explicit", rating: 2.0)
      raced_new_vote = RatingVote.new(user: user, article: article, context: "explicit")
      allow(RatingVote).to receive(:find_or_initialize_by).and_return(raced_new_vote, existing_vote)
      allow(raced_new_vote).to receive(:save).and_raise(ActiveRecord::RecordNotUnique, "duplicate key value")

      post "/rating_votes", params: {
        rating_vote: {
          article_id: article.id, group: "experience_level", rating: 9.0
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(existing_vote.reload.rating).to eq(9.0)
    end

    it "recovers when a concurrent insert causes uniqueness validation (:taken) to fail on a new vote" do
      existing_vote = create(:rating_vote, user: user, article: article, context: "explicit", rating: 2.0)
      raced_new_vote = RatingVote.new(user: user, article: article, context: "explicit")
      allow(RatingVote).to receive(:find_or_initialize_by).and_return(raced_new_vote, existing_vote)

      post "/rating_votes", params: {
        rating_vote: {
          article_id: article.id, group: "experience_level", rating: 9.0
        }
      }, as: :json

      expect(response).to have_http_status(:ok)
      expect(existing_vote.reload.rating).to eq(9.0)
    end
  end
end
