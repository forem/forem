require "rails_helper"

RSpec.describe "Badge tasks", type: :task do
  describe "award_streak_badges_backfill" do
    let(:task) { Rake::Task["award_streak_badges_backfill"] }
    let(:user) { create(:user) }

    before do
      task.reenable
      [100, 93, 86, 79].each do |days|
        create(:article, :past, user: user, published: true, past_published_at: days.days.ago)
      end
    end

    it "reports skipped thresholds without failing when badges are missing" do
      expect { task.invoke }.to output(/Skipped 4 week streak/).to_stdout
      expect(user.reload.badges).to be_empty
    end

    it "awards streak badges created after the data update script ran" do
      expect { task.invoke }.to output.to_stdout

      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      task.reenable

      expect { task.invoke }.to output(/Done!/).to_stdout
      expect(user.reload.badges.pluck(:slug)).to eq(["4-week-streak"])
    end

    it "aborts with a non-zero exit when some awards fail" do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak", credits_awarded: 5)
      allow(Rails.error).to receive(:report)
      allow(Credit).to receive(:add_to).and_raise(ActiveRecord::ConnectionTimeoutError, "simulated outage")

      exit_error = nil
      expect do
        task.invoke
      rescue SystemExit => e
        exit_error = e
      end.to output(/Backfill incomplete/).to_stderr

      expect(exit_error).to be_present
      expect(exit_error.status).not_to eq(0)
    end

    it "does not award the same badge twice when re-run" do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      expect { task.invoke }.to output.to_stdout
      task.reenable

      expect { task.invoke }.to output.to_stdout
      expect(user.reload.badges.count).to eq(1)
    end
  end
end
