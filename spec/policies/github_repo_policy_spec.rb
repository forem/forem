require "rails_helper"

RSpec.describe GithubRepoPolicy do
  subject { described_class.new(user, github_repo) }

  let(:github_repo) { build(:github_repo) }
  let(:valid_attributes) { %i[github_id_code] }

  context "when user is not signed in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the owner" do
    let(:user) { create(:user) }

    it { is_expected.to permit_actions(%i[create]) }
    it { is_expected.to forbid_actions(%i[update]) }

    context "when user is banned" do
      let(:user) { build(:user, :banned) }

      it { is_expected.to forbid_actions(%i[create update]) }
    end
  end

  context "when user is the owner" do
    let(:user) { github_repo.user }

    it { is_expected.to permit_actions(%i[create update]) }

    context "when user is banned" do
      let(:user) { build(:user, :banned) }

      it { is_expected.to forbid_actions(%i[create update]) }
    end
  end
end
