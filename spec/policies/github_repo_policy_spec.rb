require "rails_helper"

RSpec.describe GithubRepoPolicy, type: :policy do
  subject { described_class.new(user, github_repo) }

  context "when user is not signed in" do
    let(:user) { nil }
    let(:github_repo) { build(:github_repo, user: user) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when the user is not authenticated through GitHub" do
    let(:user) { build(:user) }
    let(:github_repo) { build(:github_repo, user: user) }

    it { is_expected.to forbid_actions(%i[index update_or_create]) }
  end

  context "when the user is authenticated through GitHub" do
    let(:user) { create(:user, :with_identity, identities: %i[github]) }
    let(:github_repo) { build(:github_repo, user: user) }

    before do
      omniauth_mock_github_payload
      allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
    end

    it { is_expected.to permit_actions(%i[index update_or_create]) }
  end

  context "when user is suspended" do
    let(:user) { build(:user, :suspended) }
    let(:github_repo) { build(:github_repo, user: user) }

    it { is_expected.to forbid_actions(%i[index update_or_create]) }
  end
end
