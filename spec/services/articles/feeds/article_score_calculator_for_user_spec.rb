require "rails_helper"

RSpec.describe Articles::Feeds::ArticleScoreCalculatorForUser, type: :service do
  let(:user) { create(:user) }
  let!(:article) { create(:article) }
  let(:applicator) { described_class.new(user: user) }

  describe "#score_followed_user" do
    context "when article is written by a followed user" do
      before { user.follow(article.user) }

      it "returns a score of 1" do
        expect(applicator.score_followed_user(article)).to eq 1
      end
    end

    context "when article is not written by a followed user" do
      it "returns a score of 0" do
        expect(applicator.score_followed_user(article)).to eq 0
      end
    end
  end

  describe "#score_followed_organization" do
    let(:organization) { create(:organization) }
    let(:article) { create(:article, organization: organization) }

    context "when article is from a followed organization" do
      before { user.follow(organization) }

      it "returns a score of 1" do
        expect(applicator.score_followed_organization(article)).to eq 1
      end
    end

    context "when article is not from a followed organization" do
      it "returns a score of 0" do
        expect(applicator.score_followed_organization(article)).to eq 0
      end
    end

    context "when article has no organization" do
      let(:article) { create(:article) }

      it "returns a score of 0" do
        expect(applicator.score_followed_organization(article)).to eq 0
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
        user.follows.last.update(explicit_points: 2)
      end

      it "returns the followed tag point value" do
        expect(applicator.score_followed_tags(article)).to eq 2
      end
    end

    context "when article includes multiple followed tags" do
      let(:tag2) { create(:tag) }
      let(:article) { create(:article, tags: "#{tag.name}, #{tag2.name}") }

      before do
        user.follow(tag)
        user.follow(tag2)
        user.save
        user.follows.each { |follow| follow.update(explicit_points: 2) }
      end

      it "returns the sum of followed tag point values" do
        expect(applicator.score_followed_tags(article)).to eq 4
      end
    end

    context "when article includes an unfollowed tag" do
      let(:article) { create(:article, tags: "#{tag.name}, #{unfollowed_tag.name}") }

      before do
        user.follow(tag)
        user.save
      end

      it "doesn't score the unfollowed tag" do
        expect(applicator.score_followed_tags(article)).to eq 1
      end
    end

    context "when article doesn't include any followed tags" do
      let(:article) { create(:article, tags: unfollowed_tag.name) }

      it "returns 0" do
        expect(applicator.score_followed_tags(article)).to eq 0
      end
    end

    context "when user doesn't follow any tags" do
      it "returns 0" do
        expect(user.cached_followed_tag_names).to be_empty
        expect(applicator.score_followed_tags(article)).to eq 0
      end
    end
  end

  describe "#score_experience_level" do
    let(:article) { create(:article, experience_level_rating: 7) }

    context "when user has a further experience level" do
      let(:user) { create(:user) }

      before do
        user.setting.update(experience_level: 1)
      end

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(applicator.score_experience_level(article)).to eq(-3)
      end

      it "returns proper negative when fractional" do
        article.experience_level_rating = 8
        expect(applicator.score_experience_level(article)).to eq(-3.5)
      end
    end

    context "when user has a closer experience level" do
      let(:user) { create(:user) }

      before do
        user.setting.update(experience_level: 9)
      end

      it "returns negative of (absolute value of the difference between article and user experience) divided by 2" do
        expect(applicator.score_experience_level(article)).to eq(-1)
      end
    end

    context "when the user does not have an experience level set" do
      let(:user) { create(:user) }

      before do
        user.setting.update(experience_level: nil)
      end

      it "uses a value of 5 for user experience level" do
        expect(applicator.score_experience_level(article)).to eq(-1)
      end
    end
  end

  describe "#score_comments" do
    let(:applicator) { described_class.new(user: user, config: { comment_weight: 1 }) }
    let(:article_with_one_comment) { create(:article) }
    let(:article_with_five_comments) { create(:article) }

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
        expect(applicator.score_comments(article)).to eq(0)
      end

      it "returns a multiple of the parameterized weight for articles with comments" do
        expect(article_with_five_comments.comments_count).to eq(5)
        expect(applicator.score_comments(article_with_five_comments)).to eq(5)
      end
    end

    context "when comment_weight is higher than 0" do
      before { applicator.instance_variable_set(:@comment_weight, 2) }

      it "returns 0 for uncommented articles" do
        expect(applicator.score_comments(article)).to eq(0)
      end

      it "returns a non-zero score for commented upon articles" do
        expect(applicator.score_comments(article_with_one_comment)).to be > 0
      end

      it "scores article with more comments high than others" do
        expect(applicator.score_comments(article_with_five_comments))
          .to be > applicator.score_comments(article_with_one_comment)
      end
    end
  end
end
