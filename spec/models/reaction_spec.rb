require "rails_helper"

RSpec.describe Reaction, type: :model do
  let(:user) { create(:user) }
  let(:article) { create(:article, featured: true) }
  let(:comment) { create(:comment, user: user, commentable: article) }
  let(:reaction) { build(:reaction, reactable: comment) }

  describe "validation" do
    subject { Reaction.new(reactable: article, reactable_type: "Article", user: user) }

    before { user.add_role(:trusted) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to validate_inclusion_of(:category).in_array(Reaction::CATEGORIES) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_id reactable_type category]) }

    # Thumbsdown and Vomits test needed
    # it { is_expected.to validate_inclusion_of(:reactable_type).in_array(%w(Comment Article)) }
  end

  describe "#permissions" do
    it "does not allow reaction on unpublished article" do
      article.update_column(:published, false)
      reaction = build(:reaction, user: user, reactable: article)
      expect(reaction).not_to be_valid
    end
  end

  context "when saved" do
    before do
      comment.save
      allow(Reaction::UpdateRecordsJob).to receive(:perform_later).and_call_original
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

    it "calls UpdateRecordsJob" do
      reaction.save
      expect(Reaction::UpdateRecordsJob).to have_received(:perform_later)
    end
  end

  context "when deleted" do
    before do
      allow(Reaction::UpdateRecordsJob).to receive(:perform_now).and_call_original
      reaction.destroy
    end

    it "calls UpdateRecordsJob" do
      expect(Reaction::UpdateRecordsJob).to have_received(:perform_now)
    end
  end

  context "when user does not have :trusted role" do
    it "allows like reaction" do
      reaction.category = "like"
      expect(reaction).to be_valid
    end

    it "does not allow vomit reaction for users" do
      reaction.category = "vomit"
      expect(reaction).not_to be_valid
    end

    it "does not allow thumbsdown reaction" do
      reaction.category = "thumbsdown"
      expect(reaction).not_to be_valid
    end
  end

  context "when user has :trusted role" do
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
