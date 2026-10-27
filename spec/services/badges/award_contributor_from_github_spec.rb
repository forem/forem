require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service do
  let(:user) { create(:user) }
  let(:identity) { create(:identity, user: user, provider: "github", uid: "123456", auth_data_dump: { "info" => { "nickname" => "francistrdev" } }) }

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
      allow(github_client).to receive(:search_issues).and_return(double(total_count: 0))
    end

    context "when badges do not exist in the database" do
      it "does not raise an error and logs info for missing badge slugs" do
        allow(Rails.logger).to receive(:info)

        expect {
          described_class.call
        }.not_to raise_error

        expect(Rails.logger).to have_received(:info).with(/Badge slugs not found: .*4x-commit-club/)
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

    context "when merged PR count exceeds commit count" do
      let!(:sixteen_x_commit_badge) { create(:badge, title: "16x-commit-club") }

      it "awards the badge based on merged PR count" do
        allow(github_client).to receive(:contributors).and_return([double(id: "123456", contributions: 1)])
        allow(github_client).to receive(:search_issues).with(/is:merged is:pr/).and_return(double(total_count: 20))

        described_class.call

        expect(user.badge_achievements.pluck(:badge_id)).to include(sixteen_x_commit_badge.id)
      end
    end

    context "when badges exist in the database, and github provider is a symbol" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club", allow_multiple_awards: true) }

      it "awards the expected badges with rewarding context message" do
        described_class.call

        badge_ids = user.badge_achievements.pluck(:badge_id)
        expect(badge_ids).to include(dev_contributor_badge.id)
        expect(badge_ids).to include(four_x_commit_badge.id)

        four_x_achievement = user.badge_achievements.find_by(badge_id: four_x_commit_badge.id)
        expect(four_x_achievement.rewarding_context_message_markdown).to eq(I18n.t("services.badges.thank_you"))
      end

      it "is idempotent and does not create duplicate badge achievements on repeated runs" do
        described_class.call

        expect { described_class.call }.not_to change(BadgeAchievement, :count)
        expect(user.badge_achievements.where(badge_id: four_x_commit_badge.id).count).to eq(1)
        expect(user.badge_achievements.where(badge_id: dev_contributor_badge.id).count).to eq(1)
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
