require "rails_helper"

RSpec.describe ReactionHandler, type: :service do
  # existing reaction by other user
  # existing reaction by same user, other category
  # no existing reaction = create
  # existing reaction = no-op
  # existing contradictory mod reaction

  let(:user) { create :user }
  let(:article) { create :article }
  let(:category) { "like" }

  let!(:other_category) { article.reactions.create! user: user, category: "hands" }
  let!(:other_existing) { article.reactions.create! user: create(:user), category: "like" }

  let(:moderator) { create :user, :trusted }
  let!(:contradictory_mod) { article.reactions.create! user: moderator, category: "thumbsup" }

  let(:params) do
    {
      reactable_id: article.id,
      reactable_type: article.class.polymorphic_name,
      category: category
    }
  end

  describe "#create" do
    subject(:result) { described_class.new(params, current_user: user).create }

    context "when no existing/matching reaction by user" do
      it "justs create" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "ignores other existing reactions" do
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id)
      end
    end

    context "when there's an existing/matching reaction by user" do
      let!(:existing) { article.reactions.create! user: user, category: "like" }

      it "does nothing" do
        expect(result).to be_success
        expect(result.action).to eq("none")
      end

      it "ignores other existing reactions" do
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id, existing.id)
      end
    end

    context "when there's an existing, contradictory mod reaction" do
      let(:user) { moderator }
      let(:category) { "vomit" }

      it "creates" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "destroys the other reaction as a side-effect" do
        expect(result).to be_success
        expect(Reaction.ids).not_to include(contradictory_mod.id)
      end
    end
  end

  describe "#toggle" do
    subject(:result) { described_class.new(params, current_user: user).toggle }

    context "when no existing/matching reaction by user" do
      it "justs create" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "ignores other existing reactions" do
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id)
      end
    end

    context "when there's an existing/matching reaction by user" do
      let!(:existing) { article.reactions.create! user: user, category: "like" }

      it "un-likes" do
        expect(result).to be_success
        expect(result.action).to eq("destroy")
      end

      it "ignores other existing reactions" do
        expect(Reaction.ids).to include(other_category.id, other_existing.id, contradictory_mod.id, existing.id)
      end
    end

    context "when there's an existing, contradictory mod reaction" do
      let(:user) { moderator }
      let(:category) { "vomit" }

      it "creates" do
        expect(result).to be_success
        expect(result.action).to eq("create")
      end

      it "destroys the other reaction as a side-effect" do
        expect(result).to be_success
        expect(Reaction.ids).not_to include(contradictory_mod.id)
      end
    end
  end
end
