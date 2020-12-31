require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20201217162454_cleanup_orphan_git_hub_repositories.rb",
)

describe DataUpdateScripts::CleanupOrphanGitHubRepositories do
  let(:user) { create(:user, :with_identity, identities: [:github]) }

  before do
    omniauth_mock_providers_payload
    create(:github_repo, user: user)
  end

  it "does not delete a repository if the user has a GitHub identity" do
    expect do
      described_class.new.run
    end.not_to change(user.github_repos, :count)
  end

  it "deletes a repository if the user does not have a GitHub identity" do
    github_identity = user.identities.github.first
    github_identity.destroy

    expect do
      described_class.new.run
    end.to change(user.github_repos, :count).by(-user.github_repos.size)
  end
end
