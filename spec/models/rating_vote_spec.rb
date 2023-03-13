require "rails_helper"

RSpec.describe RatingVote do
  let(:user) { create(:user, :trusted) }
  let(:user2) { create(:user, :trusted) }
  let(:article) { create(:article, user: user) }
  let(:rating_vote) { create(:rating_vote, user: user2, article: article) }

  describe "validations" do
    describe "builtin validations" do
      subject { rating_vote }

      it { is_expected.to belong_to(:article) }
      it { is_expected.to belong_to(:user).optional }

      it { is_expected.to validate_inclusion_of(:context).in_array(%w[explicit readinglist_reaction comment]) }
      it { is_expected.to validate_inclusion_of(:group).in_array(%w[experience_level]) }
      it { is_expected.to validate_numericality_of(:rating).is_greater_than(0.0).is_less_than_or_equal_to(10.0) }
      it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[article_id context]) }
    end
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

    it "does allows more than one reaction if different contexts" do
      create(:rating_vote, article_id: article.id, user_id: user.id)
      rating = build(:rating_vote, article_id: article.id, user_id: user.id, context: "readinglist_reaction")
      expect(rating).to be_valid
    end

    it "does allows more than one two reactions if all different contexts" do
      create(:rating_vote, article_id: article.id, user_id: user.id)
      create(:rating_vote, article_id: article.id, user_id: user.id, context: "readinglist_reaction")
      rating = build(:rating_vote, article_id: article.id, user_id: user.id, context: "comment")
      expect(rating).to be_valid
    end
  end

  describe "modifies article rating score" do
    before do
      allow(RatingVotes::AssignRatingWorker).to receive(:perform_async)
    end

    it "assigns article rating" do
      create(:rating_vote, article_id: article.id, user_id: user2.id, rating: 3.0)

      expect(RatingVotes::AssignRatingWorker).to have_received(:perform_async).with(article.id)
    end
  end

  describe "permissions" do
    let(:untrusted_user) { create(:user) }

    it "allows untrusted user to leave readinglist_reaction context rating" do
      rating = build(:rating_vote, article_id: article.id, user_id: untrusted_user.id, context: "readinglist_reaction")
      expect(rating).to be_valid
    end

    it "allows trusted users to make explicit rating" do
      rating = build(:rating_vote, article_id: article.id, user_id: user.id)
      expect(rating).to be_valid
    end

    it "does not allow non-trusted users to make rating" do
      rating = build(:rating_vote, article_id: article.id, user_id: untrusted_user.id)
      expect(rating).not_to be_valid
    end

    it "does allows author to make rating on own post" do
      article = create(:article, user: untrusted_user)
      rating = build(:rating_vote, article_id: article.id, user_id: untrusted_user.id)
      expect(rating).to be_valid
    end
  end
end
