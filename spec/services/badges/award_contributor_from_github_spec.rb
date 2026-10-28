require "rails_helper"

RSpec.describe Badges::AwardContributorFromGithub, type: :service do
  let(:user) { create(:user, :without_profile, profile_image: nil) }
  let(:identity) do
    create(:identity, user: user, provider: "github", uid: "123456",
                      auth_data_dump: { "info" => { "nickname" => "francistrdev" } })
  end
  let(:commit_struct) { Struct.new(:author) }
  let(:author_struct) { Struct.new(:id) }
  let(:contributor_struct) { Struct.new(:id, :contributions) }
  let(:search_results_struct) { Struct.new(:total_count, :items) }
  let(:issue_struct) { Struct.new(:user) }

  before do
    allow(Settings::Authentication).to receive(:providers).and_return([:github])
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({ provider: "github", uid: "123456" })
    # Never actually block on the Search API pacing / backoff sleeps in tests.
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(described_class).to receive(:sleep)
    # rubocop:enable RSpec/AnyInstance
  end

  describe "#throttle_search" do
    it "paces consecutive searches by the remaining SEARCH_MIN_INTERVAL" do
      service = described_class.new("thanks")
      elapsed = 1.5
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC)
        .and_return(100.0, 100.0, 100.0 + elapsed, 100.0 + described_class::SEARCH_MIN_INTERVAL.to_f)
      allow(service).to receive(:sleep)

      service.__send__(:throttle_search)
      service.__send__(:throttle_search)

      expect(service).to have_received(:sleep).with(described_class::SEARCH_MIN_INTERVAL.to_f - elapsed)
    end
  end

  describe ".call" do
    let(:commits) { [commit_struct.new(author_struct.new("123456")), commit_struct.new(nil)] }
    let(:contributors) { [contributor_struct.new("123456", 50)] }
    let(:github_client) { instance_double(Octokit::Client) }

    before do
      stub_const("#{described_class}::SEARCH_MIN_INTERVAL", 0.seconds)
      identity
      allow(Github::OauthClient).to receive(:new).and_return(github_client)
      allow(github_client).to receive(:auto_paginate=)
      # Candidate-gathering call (lists recent merged PR authors) returns .items;
      # per-user counting call returns .total_count. Default both to empty/zero.
      allow(github_client).to receive_messages(
        commits: commits,
        contributors: contributors,
        search_issues: search_results_struct.new(0, []),
      )
    end

    context "when badges do not exist in the database" do
      it "does not raise an error and logs info for missing badge slugs" do
        allow(Rails.logger).to receive(:info)

        expect do
          described_class.call
        end.not_to raise_error

        expect(Rails.logger).to have_received(:info).with(/Badge slugs not found: .*4x-commit-club/)
      end
    end

    context "when some commits have nil authors" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }

      before do
        allow(github_client).to receive(:contributors).and_return([])
      end

      it "safely ignores commits with nil authors without raising NoMethodError", :aggregate_failures do
        expect do
          described_class.call
        end.not_to raise_error

        expect(user.badge_achievements.pluck(:badge_id)).to include(dev_contributor_badge.id)
      end
    end

    context "when multiple commits have valid authors" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let(:second_user) { create(:user, :without_profile, profile_image: nil) }
      let(:commits) do
        [
          commit_struct.new(author_struct.new("123456")),
          commit_struct.new(nil),
          commit_struct.new(author_struct.new("654321")),
        ]
      end
      let(:contributors) do
        [
          contributor_struct.new("123456", 50),
          contributor_struct.new("654321", 50),
        ]
      end

      before do
        create(:identity, user: second_user, provider: "github", uid: "654321",
                          auth_data_dump: { "info" => { "nickname" => "seconddev" } })
      end

      it "awards the badge to each matching identity", :aggregate_failures do
        described_class.call

        expect(user.badge_achievements.pluck(:badge_id)).to include(dev_contributor_badge.id)
        expect(second_user.badge_achievements.pluck(:badge_id)).to include(dev_contributor_badge.id)
      end
    end

    context "when merged PR count exceeds commit count" do
      let!(:sixteen_x_commit_badge) { create(:badge, title: "16x-commit-club") }

      it "awards the badge based on merged PR count" do
        allow(github_client).to receive(:contributors).and_return([contributor_struct.new("123456", 1)])
        allow(github_client).to receive(:search_issues).with(/author:.* is:merged is:pr/, any_args)
          .and_return(search_results_struct.new(20, []))

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
          .with(/is:pr is:merged merged:>=/, any_args)
          .and_return(search_results_struct.new(0, [issue_struct.new(author_struct.new("123456"))]))
        allow(github_client).to receive(:search_issues)
          .with(/author:.* is:merged is:pr/, any_args)
          .and_return(search_results_struct.new(20, []))

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
      it "skips the per-user merged PR search" do
        allow(github_client).to receive(:contributors).and_return([contributor_struct.new("123456", 1)])
        %w[dev-contributor 4x-commit-club 8x-commit-club 16x-commit-club 32x-commit-club].each do |title|
          create(:badge_achievement, user: user, badge: create(:badge, title: title))
        end

        described_class.call

        expect(github_client).not_to have_received(:search_issues).with(/author:/, any_args)
      end
    end

    context "when badges exist in the database, and github provider is a symbol" do
      let!(:dev_contributor_badge) { create(:badge, title: "dev-contributor") }
      let!(:four_x_commit_badge) { create(:badge, title: "4x-commit-club", allow_multiple_awards: true) }

      it "awards the expected badges with rewarding context message and is idempotent", :aggregate_failures do
        described_class.call

        badge_ids = user.badge_achievements.pluck(:badge_id)
        expect(badge_ids).to include(dev_contributor_badge.id, four_x_commit_badge.id)

        four_x_achievement = user.badge_achievements.find_by(badge_id: four_x_commit_badge.id)
        expect(four_x_achievement.rewarding_context_message_markdown).to eq(I18n.t("services.badges.thank_you"))

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
