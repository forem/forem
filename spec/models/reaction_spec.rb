require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, featured: true) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:reaction) { build(:reaction, reactable: comment) }

  describe "actual validation" do
    subject { described_class.new(reactable: article, reactable_type: "Article", user: user) }

    before { user.add_role(:trusted) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Reaction::CATEGORIES) }
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
      reaction = build(:reaction, user: user, reactable: article)
      expect(reaction).to be_valid
      article.update_column(:published, false)
      reaction = build(:reaction, user: user, reactable: article)
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
      create(:reaction, user: u2, reactable: c2)
      create(:reaction, user: u2, reactable: article)
      expect(reaction).to be_valid
    end
  end

  describe "#skip_notification_for?" do
    let(:receiver) { build(:user) }
    let(:reaction2) { build(:reaction, reactable: comment, user_id: user.id + 1) }

    it "is false by default" do
      expect(reaction2.skip_notification_for?(receiver)).to be(false)
    end

    it "is true when points are negative" do
      reaction2.points = -2
      expect(reaction2.skip_notification_for?(receiver)).to be(true)
    end

    it "is true when the receiver is the same user as the one who reacted" do
      reaction.user = user
      expect(reaction.skip_notification_for?(user)).to be(true)
    end

    it "is true when the receive_notifications is false" do
      comment.receive_notifications = false
      expect(reaction.skip_notification_for?(receiver)).to be(true)
    end
  end
end
