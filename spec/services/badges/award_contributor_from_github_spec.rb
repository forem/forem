require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:identity) { create(:identity, user: user, provider: "github", uid: "123456", auth_data_dump: { "info" => { "nickname" => "francistrdev" } }) }

  before do
    allow(Settings::Authentication).to receive(:providers).and_return([:github])
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({ provider: "github", uid: "123456" })
    # Never actually block on the Search API pacing / backoff sleeps in tests.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:sleep)
    # rubocop:enable RSpec/AnyInstance
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
      allow(github_client).to receive(:auto_paginate=)
      # Candidate-gathering call (lists recent merged PR authors) returns .items;
      # per-user counting call returns .total_count. Default both to empty/zero.
      allow(github_client).to receive(:search_issues).and_return(double(total_count: 0, items: []))
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
        allow(github_client).to receive(:search_issues).with(/author:.* is:merged is:pr/, any_args)
          .and_return(double(total_count: 20))

        described_class.call

        expect(user.badge_achievements.pluck(:badge_id)).to include(sixteen_x_commit_badge.id)
      end
    end

    context "when a contributor has merged PRs but no attributed commits" do
      let!(:sixteen_x_commit_badge) { create(:badge, title: "16x-commit-club") }

      it "discovers the identity via recent merged PR authors and awards the badge" do
        # Not present in the commit contributors response...
        allow(github_client).to receive(:contributors).and_return([])
        # ...but surfaced as the author of a recently merged PR.
        allow(github_client).to receive(:search_issues)
          .with(/is:pr is:merged merged:/, any_args)
          .and_return(double(total_count: 0, items: [double(user: double(id: "123456"))]))
        allow(github_client).to receive(:search_issues)
          .with(/author:.* is:merged is:pr/, any_args)
          .and_return(double(total_count: 20))

        described_class.call

        expect(user.badge_achievements.pluck(:badge_id)).to include(sixteen_x_commit_badge.id)
      end
    end

    context "when a merged PR author only appears beyond the first search page" do
      let!(:sixteen_x_commit_badge) { create(:badge, title: "16x-commit-club") }

      it "pages through recent merged PRs and still awards the badge" do
        allow(github_client).to receive(:contributors).and_return([])

        # Page 1 is full of other authors (a full page signals there is more to
        # fetch); the eligible author only shows up on page 2.
        full_first_page = Array.new(100) { double(user: double(id: "999999")) }
        allow(github_client).to receive(:search_issues)
          .with(/is:pr is:merged merged:/, hash_including(page: 1)).and_return(double(items: full_first_page))
        allow(github_client).to receive(:search_issues)
          .with(/is:pr is:merged merged:/, hash_including(page: 2))
          .and_return(double(items: [double(user: double(id: "123456"))]))
        allow(github_client).to receive(:search_issues)
          .with(/author:.* is:merged is:pr/, any_args).and_return(double(total_count: 20))

        described_class.call

        expect(user.badge_achievements.pluck(:badge_id)).to include(sixteen_x_commit_badge.id)
      end
    end

    context "when the user already holds every awardable badge" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club") }
      let!(:eight_x_commit_badge) { create(:badge, title: "8x-commit-club") }
      let!(:sixteen_x_commit_badge) { create(:badge, title: "16x-commit-club") }
      let!(:thirty_two_x_commit_badge) { create(:badge, title: "32x-commit-club") }

      it "skips the per-user merged PR search" do
        allow(github_client).to receive(:contributors).and_return([double(id: "123456", contributions: 1)])
        [dev_contributor_badge, four_x_commit_badge, eight_x_commit_badge,
         sixteen_x_commit_badge, thirty_two_x_commit_badge].each do |badge|
          create(:badge_achievement, user: user, badge: badge)
        end

        described_class.call

        expect(github_client).not_to have_received(:search_issues).with(/author:/, any_args)
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

    context "scan window and marker" do
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club") }

      it "records the scan marker after a successful run" do
        travel_to(Time.utc(2026, 10, 28, 11, 20)) do
          described_class.call
        end

        expect(Settings::General.github_contributor_prs_scanned_through).to eq("2026-10-28")
      end

      it "scans forward from the stored marker (with overlap) on an hourly run" do
        Settings::General.github_contributor_prs_scanned_through = "2026-10-20"

        travel_to(Time.utc(2026, 10, 28, 11, 20)) do
          described_class.call
        end

        # Overlap of 2 days means the earliest slice begins at 2026-10-18.
        expect(github_client).to have_received(:search_issues)
          .with(/merged:2026-10-18\.\.2026-10-28/, any_args).at_least(:once)
      end

      it "falls back to the recent window when no marker is set" do
        Settings::General.github_contributor_prs_scanned_through = ""

        travel_to(Time.utc(2026, 10, 28, 11, 20)) do
          described_class.call
        end

        # 14-day fallback window begins at 2026-10-14.
        expect(github_client).to have_received(:search_issues)
          .with(/merged:2026-10-14\.\.2026-10-28/, any_args).at_least(:once)
      end
    end
  end

  describe ".backfill" do
    let(:github_client) { double("Github::OauthClient") }
    let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club") }

    before do
      identity
      allow(Github::OauthClient).to receive(:new).and_return(github_client)
      allow(github_client).to receive(:commits).and_return([])
      allow(github_client).to receive(:contributors).and_return([])
      allow(github_client).to receive(:auto_paginate=)
      allow(github_client).to receive(:search_issues).and_return(double(total_count: 0, items: []))
    end

    it "scans from the full history start and records the marker" do
      travel_to(Time.utc(2026, 10, 28)) do
        described_class.backfill
      end

      # The first slice of the full-history walk starts at MERGED_PR_HISTORY_START.
      expect(github_client).to have_received(:search_issues)
        .with(/merged:2018-01-01\.\./, any_args).at_least(:once)
      expect(Settings::General.github_contributor_prs_scanned_through).to eq("2026-10-28")
    end
  end
end
