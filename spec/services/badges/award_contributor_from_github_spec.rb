require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service, vcr: true do
  let(:user) { create(:user, :with_identity, identities: ["github"]) }
  let(:badge) { create(:badge, title: "DEV Contributor") }

  before do
    badge
    omniauth_mock_github_payload

    stub_const("#{described_class}::REPOSITORIES", ["rust-lang/rust"])

    user.identities.github.update_all(uid: "3372342")
  end

  it "awards contributor badge" do
    expect do
      Timecop.freeze("2020-05-15T13:49:20Z") do
        VCR.use_cassette("github_client_commits_contributor_badge") do
          described_class.call
        end
      end
    end.to change(user.badge_achievements, :count).by(1)
  end

  it "awards contributor badge once" do
    expect do
      Timecop.freeze("2020-05-15T13:49:20Z") do
        VCR.use_cassette("github_client_commits_contributor_badge_twice") do
          described_class.call
          described_class.call
        end
      end
    end.to change(user.badge_achievements, :count).by(1)
  end
end
