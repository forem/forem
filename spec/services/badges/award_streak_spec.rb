require "rails_helper"

RSpec.describe Badges::AwardStreak, type: :service do
  # Wednesday. The surrounding Monday-start (UTC) calendar weeks begin on
  # Oct 19, Oct 26, Nov 2, Nov 9 and Nov 16 (current week).
  let(:now) { Time.utc(2026, 11, 18, 12, 0, 0) }
  let(:user) { create(:user) }

  around { |example| Timecop.freeze(now) { example.run } }

  def publish(author, at, **attrs)
    create(:article, :past, user: author, published: true, past_published_at: at, **attrs)
  end

  def publish_rolling_streak(author, **attrs)
    [26, 19, 12, 5].each { |days| publish(author, days.days.ago, **attrs) }
  end

  context "with the original '4-week-streak' badge slug" do
    before do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")
      publish(user, 26.days.ago)
      publish(user, 19.days.ago)
      publish(user, 5.days.ago)
    end

    it "awards badge to users with four straight weeks of articles" do
      publish(user, 12.days.ago)
      expect do
        described_class.call(weeks: 4)
      end.to change { user.reload.badges.size }.by(1)
    end

    it "does not award a streak that ended long ago unless historical" do
      other = create(:user)
      [100, 93, 86, 79].each { |days| publish(other, days.days.ago) }

      expect { described_class.call(weeks: 4) }.not_to change { other.reload.badges.size }
      expect { described_class.call(weeks: 4, historical: true) }.to change { other.reload.badges.size }.by(1)
    end

    it "does not award the badge twice" do
      publish(user, 12.days.ago)
      described_class.call(weeks: 4)

      expect { described_class.call(weeks: 4) }.not_to change { user.reload.badges.size }
    end

    it "does not award the badge to not qualified users" do
      expect do
        described_class.call(weeks: 4)
      end.not_to change { user.reload.badges.size }
    end
  end

  context "with the '4-week-writing-streak' badge slug" do
    let!(:writing_badge) { create(:badge, title: "4 Week Writing Streak", slug: "4-week-writing-streak") }

    before { publish_rolling_streak(user) }

    it "awards the writing streak badge" do
      described_class.call(weeks: 4)

      expect(user.reload.badges).to contain_exactly(writing_badge)
    end

    it "prefers the writing streak slug when both badges exist" do
      create(:badge, title: "4 Week Streak", slug: "4-week-streak")

      described_class.call(weeks: 4)

      expect(user.reload.badges).to contain_exactly(writing_badge)
    end
  end

  context "when no badge exists for the threshold" do
    it "returns false and awards nothing" do
      publish_rolling_streak(user)

      expect(described_class.call(weeks: 4)).to be(false)
      expect(user.reload.badges).to be_empty
    end
  end

  context "with calendar week drift" do
    before { create(:badge, title: "4 Week Streak", slug: "4-week-streak") }

    # Monday of one week, then Sunday of the next: 13 days apart, which the old
    # rolling 7 day windows (counted back from "now") rejected.
    it "awards the badge across four consecutive Monday-Sunday weeks" do
      publish(user, Time.utc(2026, 10, 19, 9))  # Monday, week of Oct 19
      publish(user, Time.utc(2026, 11, 1, 20))  # Sunday, week of Oct 26
      publish(user, Time.utc(2026, 11, 2, 9))   # Monday, week of Nov 2
      publish(user, Time.utc(2026, 11, 15, 20)) # Sunday, week of Nov 9

      expect { described_class.call(weeks: 4) }.to change { user.reload.badges.size }.by(1)
    end

    it "does not award the badge when a calendar week is skipped" do
      publish(user, Time.utc(2026, 10, 19, 9))  # week of Oct 19
      publish(user, Time.utc(2026, 11, 1, 20))  # week of Oct 26
      # nothing in the week of Nov 2
      publish(user, Time.utc(2026, 11, 9, 9))   # week of Nov 9
      publish(user, Time.utc(2026, 11, 17, 9))  # week of Nov 16 (current)

      expect { described_class.call(weeks: 4) }.not_to change { user.reload.badges.size }
    end

    it "does not count several posts in one calendar week as separate weeks" do
      publish(user, Time.utc(2026, 11, 9, 9))
      publish(user, Time.utc(2026, 11, 10, 9))
      publish(user, Time.utc(2026, 11, 11, 9))
      publish(user, Time.utc(2026, 11, 12, 9))

      expect { described_class.call(weeks: 4) }.not_to change { user.reload.badges.size }
    end
  end

  context "with the bounded recurring scan" do
    before { create(:badge, title: "4 Week Streak", slug: "4-week-streak") }

    it "awards a long streak that started before the scan window" do
      # Ten consecutive Mondays from Sep 14 to Nov 16; only the last 5 weeks
      # fall inside the recurring history window.
      10.times { |i| publish(user, Time.utc(2026, 11, 16, 9) - i.weeks) }

      expect { described_class.call(weeks: 4) }.to change { user.reload.badges.size }.by(1)
    end

    it "awards a streak that ends in the previous week and starts at the window boundary" do
      # Weeks of Oct 19, Oct 26, Nov 2 and Nov 9; Oct 19 00:00 UTC is exactly
      # current_week_start - 4 weeks.
      [Time.utc(2026, 10, 19, 0), Time.utc(2026, 10, 26, 9), Time.utc(2026, 11, 2, 9), Time.utc(2026, 11, 9, 9)]
        .each { |at| publish(user, at) }

      expect { described_class.call(weeks: 4) }.to change { user.reload.badges.size }.by(1)
    end

    it "does not award authors without a post in the current or previous week" do
      # Weeks of Oct 12 to Nov 2: a full streak, but it ended two weeks ago.
      4.times { |i| publish(user, Time.utc(2026, 11, 2, 9) - i.weeks) }

      expect { described_class.call(weeks: 4) }.not_to change { user.reload.badges.size }
    end

    it "keeps the default statement timeout for recurring runs" do
      allow(ApplicationRecord).to receive(:with_statement_timeout).and_call_original
      publish_rolling_streak(user)

      described_class.call(weeks: 4)

      expect(ApplicationRecord).not_to have_received(:with_statement_timeout)
    end

    it "raises the statement timeout for the historical full-history scan" do
      allow(ApplicationRecord).to receive(:with_statement_timeout).and_call_original
      publish_rolling_streak(user)

      described_class.call(weeks: 4, historical: true)

      expect(ApplicationRecord).to have_received(:with_statement_timeout)
        .with(described_class::HISTORICAL_STATEMENT_TIMEOUT)
      expect(user.reload.badges.size).to eq(1)
    end
  end

  context "with batching and per-user failures" do
    # credits_awarded makes BadgeAchievement#award_credits call Credit.add_to,
    # which gives a class-level seam to simulate a failure for one user.
    let!(:badge) { create(:badge, title: "4 Week Streak", slug: "4-week-streak", credits_awarded: 5) }
    let(:failing_user) { create(:user) }

    def fail_awards_for(target)
      allow(Credit).to receive(:add_to).and_wrap_original do |original, recipient, amount|
        raise ActiveRecord::ConnectionTimeoutError, "simulated outage" if recipient.id == target.id

        original.call(recipient, amount)
      end
    end

    it "awards every qualifying user across multiple ID batches" do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      others = create_list(:user, 2)
      ([user] + others).each { |author| publish_rolling_streak(author) }

      described_class.call(weeks: 4)

      ([user] + others).each { |author| expect(author.reload.badges).to contain_exactly(badge) }
    end

    it "keeps going and does not raise on recurring runs when one award fails" do
      allow(Rails.error).to receive(:report)
      publish_rolling_streak(failing_user)
      publish_rolling_streak(user)
      fail_awards_for(failing_user)

      expect(described_class.call(weeks: 4)).to be(true)
      expect(user.reload.badges).to contain_exactly(badge)
      expect(failing_user.reload.badges).to be_empty
      expect(Rails.error).to have_received(:report)
        .with(an_instance_of(ActiveRecord::ConnectionTimeoutError), context: hash_including(user_id: failing_user.id))
    end

    it "raises IncompleteError after finishing a historical run with failed awards" do
      allow(Rails.error).to receive(:report)
      publish_rolling_streak(failing_user)
      publish_rolling_streak(user)
      fail_awards_for(failing_user)

      expect { described_class.call(weeks: 4, historical: true) }
        .to raise_error(described_class::IncompleteError, /1 award\(s\) failed.*#{failing_user.id}/)
      expect(user.reload.badges).to contain_exactly(badge)
    end

    it "makes the backfill raise after attempting every threshold" do
      allow(Rails.error).to receive(:report)
      eight_week_badge = create(:badge, title: "8 Week Streak", slug: "8-week-streak")
      publish_rolling_streak(failing_user)
      8.times { |i| publish(user, (i * 7 + 2).days.ago) }
      fail_awards_for(failing_user)

      expect { described_class.backfill }.to raise_error(described_class::IncompleteError)
      expect(user.reload.badges).to contain_exactly(badge, eight_week_badge)
    end
  end

  context "with quality and moderation guards" do
    before { create(:badge, title: "4 Week Streak", slug: "4-week-streak") }

    it "does not count articles scored at or below the minimum quality" do
      [26, 19, 12].each { |days| publish(user, days.days.ago) }
      publish(user, 5.days.ago).update_column(:score, described_class::MINIMUM_QUALITY)

      expect { described_class.call(weeks: 4) }.not_to change { user.reload.badges.size }
    end

    it "counts articles scored just above the minimum quality" do
      [26, 19, 12].each { |days| publish(user, days.days.ago) }
      publish(user, 5.days.ago).update_column(:score, described_class::MINIMUM_QUALITY + 1)

      expect { described_class.call(weeks: 4) }.to change { user.reload.badges.size }.by(1)
    end

    it "does not award the badge to spam users" do
      spammer = create(:user).tap { |u| u.add_role(:spam) }
      publish_rolling_streak(spammer)

      expect { described_class.call(weeks: 4) }.not_to change { spammer.reload.badges.size }
    end

    it "does not award the badge to suspended users" do
      suspended = create(:user).tap { |u| u.add_role(:suspended) }
      publish_rolling_streak(suspended)

      expect { described_class.call(weeks: 4) }.not_to change { suspended.reload.badges.size }
    end

    it "does not award the badge to banished users" do
      banished = create(:user, username: "spam_#{SecureRandom.hex(4)}")
      publish_rolling_streak(banished)

      expect { described_class.call(weeks: 4) }.not_to change { banished.reload.badges.size }
    end

    it "still awards eligible users alongside excluded ones" do
      spammer = create(:user).tap { |u| u.add_role(:spam) }
      publish_rolling_streak(spammer)
      publish_rolling_streak(user)

      expect { described_class.call(weeks: 4) }.to change { user.reload.badges.size }.by(1)
    end
  end
end
