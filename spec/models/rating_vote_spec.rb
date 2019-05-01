require "rails_helper"

RSpec.describe RatingVote, type: :model do
  let(:user) { create(:user, :trusted) }
  let(:user2)        { create(:user, :trusted) }
  let(:user3)        { create(:user, :trusted) }
  let(:article) { create(:article, user_id: user.id) }

  describe "validations" do
    it { is_expected.to validate_numericality_of(:rating).is_greater_than(0.0).is_less_than_or_equal_to(10.0) }
    it { is_expected.to validate_inclusion_of(:group).in_array(%w[experience_level]) }
  end

  describe "uniqueness" do
    it "does allow a user to create one rating for one article" do
      rating = build(:rating_vote, article_id: article.id, user_id: user.id)
      expect(rating).to be_valid
    end
    it "does not allow a user to create multiple ratings for one article" do
      create(:rating_vote, article_id: article.id, user_id: user.id)
      rating = build(:rating_vote, article_id: article.id, user_id: user.id)
      expect(rating).not_to be_valid
    end
  end

  describe "modifies article rating score" do
    it "assigns article rating" do
      rating = create(:rating_vote, article_id: article.id, user_id: user.id, rating: 2.0)
      create(:rating_vote, article_id: article.id, user_id: user2.id, rating: 3.0)
      rating.assign_article_rating
      expect(article.reload.experience_level_rating).to eq(2.5)
      expect(article.reload.experience_level_rating_distribution).to eq(1.0)
    end

    it "assigns article rating with larger distribution" do
      rating = create(:rating_vote, article_id: article.id, user_id: user.id, rating: 1.0)
      create(:rating_vote, article_id: article.id, user_id: user2.id, rating: 7.0)
      rating.assign_article_rating
      expect(article.reload.experience_level_rating).to eq(4.0)
      expect(article.reload.experience_level_rating_distribution).to eq(6.0)
    end
  end

  describe "permissions" do
    it "allows trusted users to make rating" do
      rating = build(:rating_vote, article_id: article.id, user_id: user.id)
      expect(rating).to be_valid
    end

    it "does not allow non-trusted users to make rating" do
      nontrusted_user = create(:user)
      rating = build(:rating_vote, article_id: article.id, user_id: nontrusted_user.id)
      expect(rating).not_to be_valid
    end

    it "does allows author to make rating on own post" do
      nontrusted_user = create(:user)
      article = create(:article, user_id: nontrusted_user.id)
      rating = build(:rating_vote, article_id: article.id, user_id: nontrusted_user.id)
      expect(rating).to be_valid
    end
  end
end
