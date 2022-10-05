require "rails_helper"

RSpec.describe ReactionPolicy do
  subject { described_class.new(user, reaction) }

  let(:comment) { create(:comment, commentable: create(:article)) }
  let(:reaction) { create(:reaction, reactable: comment) }
  let!(:user) { create(:user) }

  describe ".policy_query_for" do
    subject { described_class.policy_query_for(category: category) }

    ReactionCategory.privileged.each do |category|
      context "when #{category} cateogry" do
        let(:category) { category.to_s }

        it { is_expected.to eq(:privileged_create?) }
      end
    end

    (ReactionCategory.all_slugs - ReactionCategory.privileged).each do |category|
      context "when #{category} category" do
        let(:category) { category.to_s }

        it { is_expected.to eq(:create?) }
      end
    end

    context "when nil category" do
      let(:category) { nil }

      it { is_expected.to eq(:create?) }
    end
  end

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed in" do
    it { is_expected.to permit_actions(%i[index create]) }

    context "when user is suspended" do
      before { user.add_role(:suspended) }

      it { is_expected.to permit_actions(%i[index create]) }
      it { is_expected.to forbid_actions(%i[privileged_create]) }
    end

    context "when user is unadorned with roles" do
      it { is_expected.to permit_actions(%i[index create]) }
      it { is_expected.to forbid_actions(%i[privileged_create]) }
    end

    context "when user is trusted" do
      before { user.add_role(:trusted) }

      it { is_expected.to permit_actions(%i[index create privileged_create]) }
    end

    context "when user is super admin" do
      let(:user) { create(:user, :super_admin) }

      it { is_expected.to permit_actions(%i[index create privileged_create]) }
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to permit_actions(%i[index create privileged_create]) }
    end
  end
end
