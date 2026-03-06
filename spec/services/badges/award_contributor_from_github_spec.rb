require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service do
  let(:user) { create(:user) }
  let(:identity) { create(:identity, user: user, provider: "github", uid: "123456") }

  before do
    allow(Settings::Authentication).to receive(:providers).and_return([:github])
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({ provider: "github", uid: "123456" })
  end

  describe ".call" do
    let(:commits) { [double(author: double(id: "123456")), double(author: nil)] }
    let(:contributors) { [double(id: "123456", contributions: 50)] }
    let(:github_client) { double("Github::OauthClient") }

    before do
      identity
      allow(Github::OauthClient).to receive(:new).and_return(github_client)
      allow(github_client).to receive(:commits).and_return(commits)
      allow(github_client).to receive(:contributors).and_return(contributors)
    end

    context "when badges do not exist in the database" do
      it "does not raise an error due to nil badge IDs when creating badge achievements" do
        expect {
          described_class.call
        }.not_to raise_error
      end
    end

    context "when some commits have nil authors" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }

      it "safely ignores commits with nil authors without raising NoMethodError" do
        expect {
          described_class.call
        }.not_to raise_error
      end
    end

    context "when badges exist in the database, and github provider is a symbol" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club") }

      it "awards the expected badges" do
        described_class.call

        badge_ids = user.badge_achievements.pluck(:badge_id)
        expect(badge_ids).to include(dev_contributor_badge.id)
        expect(badge_ids).to include(four_x_commit_badge.id)
      end
    end

    context "when badges exist in the database, and github provider is a string" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club") }

      before do
        allow(Settings::Authentication).to receive(:providers).and_return(["github"])
      end

      it "awards the expected badges" do
        described_class.call

        badge_ids = user.badge_achievements.pluck(:badge_id)
        expect(badge_ids).to include(dev_contributor_badge.id)
        expect(badge_ids).to include(four_x_commit_badge.id)
      end
    end
  end
end
