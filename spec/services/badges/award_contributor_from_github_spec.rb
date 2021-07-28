require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service, vcr: true do
  let(:badge) { create(:badge, title: "DEV Contributor") }

  before do
    badge
    omniauth_mock_github_payload
    stub_const("#{described_class}::REPOSITORIES", ["forem/DEV-Android"])
  end

  it "awards contributor badge" do
    user = create(:user, :with_identity, identities: ["github"], uid: "389169")
    expect do
      VCR.use_cassette("github_client_commits_contributor_badge") do
        described_class.call
      end
    end.to change(user.badge_achievements, :count).by(1)
  end

  it "awards contributor badge once" do
    user = create(:user, :with_identity, identities: ["github"], uid: "389169")
    expect do
      VCR.use_cassette("github_client_commits_contributor_badge", allow_playback_repeats: true) do
        described_class.call
        described_class.call
      end
    end.to change(user.badge_achievements, :count).by(1)
  end

  it "awards bronze contributor badge" do
    badge = create(:badge, title: "DEV Contributor Bronze")
    user = create(:user, :with_identity, identities: ["github"], uid: "459464")
    VCR.use_cassette("github_client_commits_contributor_badge") do
      expect do
        described_class.call
      end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
    end
  end

  it "awards silver contributor badge" do
    badge = create(:badge, title: "DEV Contributor Silver")
    user = create(:user, :with_identity, identities: ["github"], uid: "6045239")
    VCR.use_cassette("github_client_commits_contributor_badge") do
      expect do
        described_class.call
      end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
    end
  end

  it "awards gold contributor badge" do
    badge = create(:badge, title: "DEV Contributor Gold")
    user = create(:user, :with_identity, identities: ["github"], uid: "15793250")
    VCR.use_cassette("github_client_commits_contributor_badge") do
      expect do
        described_class.call
      end.to change(user.badge_achievements.where(badge: badge), :count).by(1)
    end
  end
end
