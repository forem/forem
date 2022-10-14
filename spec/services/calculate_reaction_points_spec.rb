require "rails_helper"

RSpec.describe CalculateReactionPoints, type: :service do
  let(:user) { create(:user, registered_at: 20.days.ago) }
  let(:article) { create(:article, user: user) }
  let(:reaction) { build(:reaction, reactable: article, user: user) }
  let(:calculated_points) { described_class.call(reaction) }

  it "assigns 0 points if reaction is invalid" do
    reaction.status = "invalid"
    expect(calculated_points).to eq(0)
  end

  context "when reaction is to comment on author's post" do
    let(:comment) { build :comment, commentable: article }
    let(:reaction) { build :reaction, reactable: comment, user: user }

    it "assigns extra 5 points" do
      expect(calculated_points).to eq(5.0)
    end

    it "does not extra 5 points if comment from other author" do
      second_user = create(:user)
      second_article = create(:article, user: second_user)
      comment = create(:comment, commentable: second_article)
      comment_reaction = create(:reaction, reactable: comment, user: user)
      expect(comment_reaction.points).to eq(1)
    end
  end

  it "assigns the correct points if reaction is confirmed" do
    reaction_points = reaction.points
    reaction.status = "confirmed"
    expect(calculated_points).to eq(reaction_points * 2)
  end

  context "when newish user" do
    let(:newish_user) { create(:user, registered_at: 3.days.ago) }
    let(:reaction) { build :reaction, reactable: article, user: newish_user }

    it "assigns fractional points to new users on create" do
      expect(calculated_points).to be_within(0.1).of(0.3)
    end

    it "assigns full points to new user who is also trusted" do
      allow(newish_user).to receive(:trusted?).and_return(true)
      expect(calculated_points).to be_within(0.1).of(1.0)
    end

    it "assigns full points to new users who is admin" do
      newish_user.add_role(:admin)
      expect(calculated_points).to be_within(0.1).of(1.0)
    end
  end

  it "Does not assign new fractional logic on re-save" do
    reaction.save
    original_points = reaction.points
    reaction.user.update_column(:registered_at, 7.days.ago)

    expect(calculated_points).to eq(original_points)
  end
end
