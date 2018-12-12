# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user)        { create(:user) }
  let(:author)      { create(:user) }
  let(:article)     { create(:article, user_id: author.id, featured: true) }
  let(:comment) do
    create(:comment, user_id: user.id, commentable_id: article.id, commentable_type: "Article")
  end
  let(:reaction) do
    build(:reaction, reactable: comment, reactable_type: "Comment")
  end

  describe "actual validation" do
    subject { Reaction.new(reactable: article, reactable_type: "Article", user: user) }

    before { user.add_role(:trusted) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(%w(like thinking hands unicorn thumbsdown vomit readinglist)) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_id reactable_type category]) }

    # Thumbsdown and Vomits test needed
    # it { is_expected.to validate_inclusion_of(:reactable_type).in_array(%w(Comment Article)) }
  end

  describe "validations" do
    it "allows like reaction for users without trusted role" do
      reaction.category = "like"
      expect(reaction).to be_valid
    end

    it "does not allow reactions outside of allowed list" do
      reaction.category = "woozlewazzle"
      expect(reaction).not_to be_valid
    end

    it "does not allow vomit reaction for users without trusted role" do
      reaction.category = "vomit"
      expect(reaction).not_to be_valid
    end

    it "does not allow thumbsdown reaction for users without trusted role" do
      reaction.category = "thumbsdown"
      expect(reaction).not_to be_valid
    end

    it "does not allow reaction on unpublished article" do
      reaction = build(
        :reaction, user_id: user.id, reactable_id: article.id, reactable_type: "Article"
      )
      expect(reaction).to be_valid
      article.update_column(:published, false)
      reaction = build(
        :reaction, user_id: user.id, reactable_id: article.id, reactable_type: "Article"
      )
      expect(reaction).not_to be_valid
    end

    it "assigns 0 points if reaction is invalid" do
      reaction.update(status: "invalid")
      expect(reaction.points).to eq(0)
    end

    it "assigns the correct points if reaction is confirmed" do
      reaction_points = reaction.points
      reaction.update(status: "confirmed")
      expect(reaction.points).to eq(reaction_points * 2)
    end

    context "when user is trusted" do
      before { reaction.user.add_role(:trusted) }

      it "allows vomit reactions for users with trusted role" do
        reaction.category = "vomit"
        expect(reaction).to be_valid
      end

      it "allows thumbsdown reactions for users with trusted role" do
        reaction.category = "thumbsdown"
        expect(reaction).to be_valid
      end
    end
  end

  describe "async callbacks" do
    it "runs async jobs effectively" do
      u2 = create(:user)
      c2 = create(:comment, commentable_id: article.id)
      create(:reaction, user_id: u2.id, reactable_id: c2.id, reactable_type: "Comment")
      create(:reaction, user_id: u2.id, reactable_id: article.id, reactable_type: "Article")
      expect(reaction).to be_valid
    end
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
