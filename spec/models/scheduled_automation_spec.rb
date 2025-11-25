require "rails_helper"

RSpec.describe ScheduledAutomation, type: :model do
  let(:bot) { create(:user, type_of: :community_bot) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:scheduled_automation, user: bot) }

    it { is_expected.to validate_presence_of(:frequency) }
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:service_name) }
    it { is_expected.to validate_presence_of(:state) }

    it { is_expected.to validate_inclusion_of(:frequency).in_array(%w[daily weekly hourly custom_interval]) }
    it { is_expected.to validate_inclusion_of(:action).in_array(%w[create_draft publish_article]) }
    it { is_expected.to validate_inclusion_of(:state).in_array(%w[active running completed failed]) }

    context "when user is not a community bot" do
      let(:regular_user) { create(:user, type_of: :member) }
      
      it "is invalid" do
        automation = build(:scheduled_automation, user: regular_user)
        expect(automation).not_to be_valid
        expect(automation.errors[:user]).to include("must be a community bot")
      end
    end

    context "when user is a community bot" do
      it "is valid" do
        automation = build(:scheduled_automation, user: bot)
        expect(automation).to be_valid
      end
    end
  end

  describe "frequency_config normalization" do
    it "converts string values to integers before validation" do
      automation = build(:scheduled_automation,
                        user: bot,
                        frequency: "daily",
                        frequency_config: { "hour" => "9", "minute" => "30" })
      expect(automation).to be_valid
      expect(automation.frequency_config["hour"]).to eq(9)
      expect(automation.frequency_config["minute"]).to eq(30)
    end

    it "keeps integer values as integers" do
      automation = build(:scheduled_automation,
                        user: bot,
                        frequency: "weekly",
                        frequency_config: { "day_of_week" => 5, "hour" => 9, "minute" => 0 })
      expect(automation).to be_valid
      expect(automation.frequency_config["day_of_week"]).to eq(5)
      expect(automation.frequency_config["hour"]).to eq(9)
      expect(automation.frequency_config["minute"]).to eq(0)
    end

    it "preserves non-numeric string values" do
      automation = build(:scheduled_automation, user: bot)
      automation.frequency_config = { "hour" => "9", "note" => "test note" }
      automation.valid? # Trigger before_validation callback
      expect(automation.frequency_config["hour"]).to eq(9)
      expect(automation.frequency_config["note"]).to eq("test note")
    end

    it "handles mixed integer and string values" do
      automation = build(:scheduled_automation,
                        user: bot,
                        frequency: "weekly",
                        frequency_config: { "day_of_week" => "5", "hour" => 9, "minute" => "0" })
      expect(automation).to be_valid
      expect(automation.frequency_config["day_of_week"]).to eq(5)
      expect(automation.frequency_config["hour"]).to eq(9)
      expect(automation.frequency_config["minute"]).to eq(0)
    end
  end

  describe "frequency_config validations" do
    context "with hourly frequency" do
      it "is valid with correct minute" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "hourly", 
                          frequency_config: { "minute" => 30 })
        expect(automation).to be_valid
      end

      it "is invalid without minute" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "hourly", 
                          frequency_config: {})
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("must include 'minute' for hourly frequency")
      end

      it "is invalid with minute out of range" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "hourly", 
                          frequency_config: { "minute" => 60 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("minute must be an integer between 0 and 59")
      end
    end

    context "with daily frequency" do
      it "is valid with correct hour and minute" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "daily", 
                          frequency_config: { "hour" => 9, "minute" => 30 })
        expect(automation).to be_valid
      end

      it "is invalid without hour" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "daily", 
                          frequency_config: { "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("must include 'hour' for daily frequency")
      end

      it "is invalid with hour out of range" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "daily", 
                          frequency_config: { "hour" => 24, "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("hour must be an integer between 0 and 23")
      end
    end

    context "with weekly frequency" do
      it "is valid with correct day_of_week, hour, and minute" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "weekly", 
                          frequency_config: { "day_of_week" => 5, "hour" => 9, "minute" => 30 })
        expect(automation).to be_valid
      end

      it "is invalid without day_of_week" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "weekly", 
                          frequency_config: { "hour" => 9, "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("must include 'day_of_week' for weekly frequency")
      end

      it "is invalid with day_of_week out of range" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "weekly", 
                          frequency_config: { "day_of_week" => 7, "hour" => 9, "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("day_of_week must be an integer between 0 (Sunday) and 6 (Saturday)")
      end
    end

    context "with custom_interval frequency" do
      it "is valid with correct interval_days, hour, and minute" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "custom_interval", 
                          frequency_config: { "interval_days" => 7, "hour" => 9, "minute" => 30 })
        expect(automation).to be_valid
      end

      it "is invalid without interval_days" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "custom_interval", 
                          frequency_config: { "hour" => 9, "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("must include 'interval_days' for custom_interval frequency")
      end

      it "is invalid with interval_days less than 1" do
        automation = build(:scheduled_automation, 
                          user: bot, 
                          frequency: "custom_interval", 
                          frequency_config: { "interval_days" => 0, "hour" => 9, "minute" => 30 })
        expect(automation).not_to be_valid
        expect(automation.errors[:frequency_config]).to include("interval_days must be a positive integer")
      end
    end
  end

  describe "scopes" do
    let!(:enabled_automation) { create(:scheduled_automation, user: bot, enabled: true) }
    let!(:disabled_automation) { create(:scheduled_automation, user: bot, enabled: false) }
    let!(:active_automation) { create(:scheduled_automation, user: bot, state: "active") }
    let!(:running_automation) { create(:scheduled_automation, user: bot, state: "running") }
    let!(:due_automation) { create(:scheduled_automation, user: bot, next_run_at: 5.minutes.ago) }
    let!(:future_automation) { create(:scheduled_automation, user: bot, next_run_at: 5.minutes.from_now) }

    describe ".enabled" do
      it "returns only enabled automations" do
        expect(described_class.enabled).to include(enabled_automation)
        expect(described_class.enabled).not_to include(disabled_automation)
      end
    end

    describe ".active" do
      it "returns only active automations" do
        expect(described_class.active).to include(active_automation)
        expect(described_class.active).not_to include(running_automation)
      end
    end

    describe ".due_for_execution" do
      it "returns enabled, active automations with next_run_at in the past" do
        expect(described_class.due_for_execution).to include(due_automation)
        expect(described_class.due_for_execution).not_to include(future_automation)
        expect(described_class.due_for_execution).not_to include(disabled_automation)
        expect(described_class.due_for_execution).not_to include(running_automation)
      end
    end
  end

  describe "#calculate_next_run_time" do
    let(:base_time) { Time.zone.parse("2024-01-15 10:30:00") }

    context "with hourly frequency" do
      let(:automation) do
        build(:scheduled_automation, 
              user: bot, 
              frequency: "hourly", 
              frequency_config: { "minute" => 15 })
      end

      it "calculates next run at the specified minute of the current hour" do
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-15 11:15:00"))
      end

      it "schedules for next hour if time has passed" do
        base_time = Time.zone.parse("2024-01-15 10:20:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-15 11:15:00"))
      end
    end

    context "with daily frequency" do
      let(:automation) do
        build(:scheduled_automation, 
              user: bot, 
              frequency: "daily", 
              frequency_config: { "hour" => 9, "minute" => 0 })
      end

      it "calculates next run at the specified time today" do
        base_time = Time.zone.parse("2024-01-15 08:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-15 09:00:00"))
      end

      it "schedules for tomorrow if time has passed" do
        base_time = Time.zone.parse("2024-01-15 10:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-16 09:00:00"))
      end
    end

    context "with weekly frequency" do
      let(:automation) do
        build(:scheduled_automation, 
              user: bot, 
              frequency: "weekly", 
              frequency_config: { "day_of_week" => 5, "hour" => 9, "minute" => 0 }) # Friday
      end

      it "calculates next run on the specified day of week" do
        # Monday Jan 15, 2024
        base_time = Time.zone.parse("2024-01-15 08:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        # Should be Friday Jan 19, 2024 at 9:00
        expect(next_run).to eq(Time.zone.parse("2024-01-19 09:00:00"))
      end

      it "schedules for next week if on same day but time has passed" do
        # Friday Jan 19, 2024 at 10:00 (after 9:00)
        base_time = Time.zone.parse("2024-01-19 10:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        # Should be Friday Jan 26, 2024 at 9:00
        expect(next_run).to eq(Time.zone.parse("2024-01-26 09:00:00"))
      end
    end

    context "with custom_interval frequency" do
      let(:automation) do
        build(:scheduled_automation, 
              user: bot, 
              frequency: "custom_interval", 
              frequency_config: { "interval_days" => 7, "hour" => 9, "minute" => 0 })
      end

      it "calculates next run based on interval from last run" do
        automation.last_run_at = Time.zone.parse("2024-01-15 09:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-22 09:00:00"))
      end

      it "schedules for today if no last run and time hasn't passed" do
        automation.last_run_at = nil
        base_time = Time.zone.parse("2024-01-15 08:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-15 09:00:00"))
      end

      it "schedules for tomorrow if no last run and time has passed" do
        automation.last_run_at = nil
        base_time = Time.zone.parse("2024-01-15 10:00:00")
        next_run = automation.calculate_next_run_time(base_time)
        expect(next_run).to eq(Time.zone.parse("2024-01-16 09:00:00"))
      end
    end
  end

  describe "#mark_as_running!" do
    let(:automation) { create(:scheduled_automation, user: bot, state: "active") }

    it "updates state to running" do
      expect { automation.mark_as_running! }
        .to change { automation.state }.from("active").to("running")
    end
  end

  describe "#mark_as_completed!" do
    let(:automation) { create(:scheduled_automation, user: bot, state: "running") }
    let(:next_run_time) { 1.hour.from_now }

    it "updates state to active and sets next run time" do
      expect { automation.mark_as_completed!(next_run_time) }
        .to change { automation.state }.from("running").to("active")
        .and change { automation.last_run_at }.from(nil)
        .and change { automation.next_run_at }

      expect(automation.next_run_at).to be_within(1.second).of(next_run_time)
    end
  end

  describe "#mark_as_failed!" do
    let(:automation) { create(:scheduled_automation, user: bot, state: "running") }

    it "updates state to failed" do
      expect { automation.mark_as_failed! }
        .to change { automation.state }.from("running").to("failed")
    end
  end

  describe "#set_next_run_time!" do
    let(:automation) do
      build(:scheduled_automation, 
            user: bot, 
            frequency: "daily", 
            frequency_config: { "hour" => 9, "minute" => 0 },
            next_run_at: nil)
    end

    it "sets the next run time if not already set" do
      expect(automation.next_run_at).to be_nil
      automation.set_next_run_time!
      automation.reload
      expect(automation.next_run_at).not_to be_nil
    end

    it "does not change next run time if already set" do
      automation.next_run_at = 1.day.from_now
      automation.save!
      original_time = automation.next_run_at
      
      automation.set_next_run_time!
      expect(automation.next_run_at).to eq(original_time)
    end
  end
end

