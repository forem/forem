require "rails_helper"

RSpec.describe Articles::Score, type: :service do
  let(:user) { create(:user) }
  let(:tag_weight) { 1 }
  let(:randomness) { 3 }
  let(:comment_weight) { 0 }
  let(:experience_level_weight) { 1 }
  let!(:article) { create(:article) }
  let!(:score) do
    described_class.new(
      user: user,
      article: article,
      tag_weight: tag_weight,
      randomness: randomness,
      comment_weight: comment_weight,
      experience_level_weight: experience_level_weight,
    )
  end

  describe "#score_followed_user" do
    context "when article is written by a followed user" do
      before { user.follow(article.user) }

      it "returns a score of 1" do
        expect(score.score_followed_user).to eq 1
      end
    end

    context "when article is not written by a followed user" do
      it "returns a score of 0" do
        expect(score.score_followed_user).to eq 0
      end
    end
  end

  describe "#score_followed_organization" do
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }

    context "when article is from a followed organization" do
      before { user.follow(organization) }

      it "returns a score of 1" do
        expect(score.score_followed_organization).to eq 1
      end
    end

    context "when article is not from a followed organization" do
      it "returns a score of 0" do
        expect(score.score_followed_organization).to eq 0
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article) }

      it "returns a score of 0" do
        expect(score.score_followed_organization).to eq 0
      end
    end
  end

  describe "#score_randomness" do
    context "when random number is less than 0.6 but greater than 0.3" do
      it "returns 6" do
        allow(score).to receive(:rand).and_return(2)
        expect(score.score_randomness).to eq 6
      end
    end

    context "when random number is less than 0.3" do
      it "returns 3" do
        allow(score).to receive(:rand).and_return(1)
        expect(score.score_randomness).to eq 3
      end
    end

    context "when random number is greater than 0.6" do
      it "returns 0" do
        allow(score).to receive(:rand).and_return(0)
        expect(score.score_randomness).to eq 0
      end
    end
  end

  describe "#score_language" do
    context "when article is in a user's preferred language" do
      it "returns a score of 1" do
        expect(score.score_language).to eq 1
      end
    end

    context "when article is not in user's prferred language" do
      before { article.language = "de" }

      it "returns a score of -10" do
        expect(score.score_language).to eq(-15)
      end
    end

    context "when article doesn't have a language, assume english" do
      before { article.language = nil }

      it "returns a score of 1" do
        expect(score.score_language).to eq 1
      end
    end
  end

  describe "#score_followed_tags" do
    let(:tag) { create(:tag) }
    let(:unfollowed_tag) { create(:tag) }

    context "when article includes a followed tag" do
      let(:article) { create(:article, tags: tag.name) }

      before do
        user.follow(tag)
        user.save
        user.follows.last.update(points: 2)
      end

      it "returns the followed tag point value" do
        expect(score.score_followed_tags).to eq 2
      end
    end

    context "when article includes multiple followed tags" do
      let(:tag2) { create(:tag) }
      let(:article) { create(:article, tags: "#{tag.name}, #{tag2.name}") }

      before do
        user.follow(tag)
        user.follow(tag2)
        user.save
        user.follows.each { |follow| follow.update(points: 2) }
      end

      it "returns the sum of followed tag point values" do
        expect(score.score_followed_tags).to eq 4
      end
    end

    context "when article includes an unfollowed tag" do
      let(:article) { create(:article, tags: "#{tag.name}, #{unfollowed_tag.name}") }

      before do
        user.follow(tag)
        user.save
      end

      it "doesn't score the unfollowed tag" do
        expect(score.score_followed_tags).to eq 1
      end
    end

    context "when article doesn't include any followed tags" do
      let(:article) { create(:article, tags: unfollowed_tag.name) }

      it "returns 0" do
        expect(score.score_followed_tags).to eq 0
      end
    end

    context "when user doesn't follow any tags" do
      it "returns 0" do
        expect(user.cached_followed_tag_names).to be_empty
        expect(score.score_followed_tags).to eq 0
      end
    end
  end

  describe "#score_experience_level" do
    let(:article) { create(:article, experience_level_rating: 7) }

    context "when user has a further experience level" do
      let(:user) { create(:user, experience_level: 1) }

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(score.score_experience_level).to eq(-3)
      end

      it "returns  proper negative when fractional" do
        article.experience_level_rating = 8
        expect(score.score_experience_level).to eq(-3.5)
      end
    end

    context "when user has a closer experience level" do
      let(:user) { create(:user, experience_level: 9) }

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(score.score_experience_level).to eq(-1)
      end
    end

    context "when the user does not have an experience level set" do
      let(:user) { create(:user, experience_level: nil) }

      it "uses a value of 5 for user experience level" do
        expect(score.score_experience_level).to eq(-1)
      end
    end
  end

  describe "#score_comments" do
    let(:article_with_one_comment) { create(:article) }
    let(:article_with_five_comments) { create(:article) }
    let(:score_article_one_comment) do
      described_class.new(
        user: user,
        article: article_with_one_comment,
        tag_weight: tag_weight,
        randomness: randomness,
        comment_weight: comment_weight,
        experience_level_weight: experience_level_weight,
      )
    end
    let(:score_article_five_comments) do
      described_class.new(
        user: user,
        article: article_with_five_comments,
        tag_weight: tag_weight,
        randomness: randomness,
        comment_weight: comment_weight,
        experience_level_weight: experience_level_weight,
      )
    end

    before do
      create(:comment, user: user, commentable: article_with_one_comment)
      create_list(:comment, 5, user: user, commentable: article_with_five_comments)
      article_with_one_comment.update_score
      article_with_five_comments.update_score
      article_with_one_comment.reload
      article_with_five_comments.reload
    end

    context "when comment_weight is default of 0" do
      it "returns 0 for uncommented articles" do
        expect(score.score_comments).to eq(0)
      end

      it "returns 0 for articles with comments" do
        expect(article_with_five_comments.comments_count).to eq(5)
        expect(score_article_five_comments.score_comments).to eq(0)
      end
    end

    context "when comment_weight is higher than 0" do
      before do
        score.instance_variable_set(:@comment_weight, 2)
        score_article_one_comment.instance_variable_set(:@comment_weight, 2)
        score_article_five_comments.instance_variable_set(:@comment_weight, 2)
      end

      it "returns 0 for uncommented articles" do
        expect(score.score_comments).to eq(0)
      end

      it "returns a non-zero score for commented upon articles" do
        expect(score_article_one_comment.score_comments).to be > 0
      end

      it "scores article with more comments high than others" do
        expect(score_article_five_comments.score_comments).to be > score_article_one_comment.score_comments
      end
    end
  end
end
