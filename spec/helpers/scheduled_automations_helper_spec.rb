require "rails_helper"

RSpec.describe ScheduledAutomationsHelper, type: :helper do
  let(:bot) { create(:user, type_of: :community_bot) }

  describe "#format_frequency" do
    context "with hourly frequency" do
      it "formats with integer values" do
        automation = build(:scheduled_automation, 
                          user: bot,
                          frequency: "hourly",
                          frequency_config: { "minute" => 30 })
        
        expect(helper.format_frequency(automation)).to eq("Every hour at minute 30")
      end

      it "formats with string values (from form params)" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "hourly",
                          frequency_config: { "minute" => "30" })
        
        expect(helper.format_frequency(automation)).to eq("Every hour at minute 30")
      end
    end

    context "with daily frequency" do
      it "formats with integer values" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "daily",
                          frequency_config: { "hour" => 9, "minute" => 30 })
        
        expect(helper.format_frequency(automation)).to eq("Daily at 09:30 AM UTC")
      end

      it "formats with string values (from form params)" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "daily",
                          frequency_config: { "hour" => "9", "minute" => "30" })
        
        expect(helper.format_frequency(automation)).to eq("Daily at 09:30 AM UTC")
      end
    end

    context "with weekly frequency" do
      it "formats with integer values" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "weekly",
                          frequency_config: { "day_of_week" => 5, "hour" => 9, "minute" => 0 })
        
        expect(helper.format_frequency(automation)).to eq("Every Friday at 09:00 AM UTC")
      end

      it "formats with string values (from form params)" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "weekly",
                          frequency_config: { "day_of_week" => "5", "hour" => "9", "minute" => "0" })
        
        expect(helper.format_frequency(automation)).to eq("Every Friday at 09:00 AM UTC")
      end

      it "handles all days of the week correctly" do
        (0..6).each do |day|
          automation = build(:scheduled_automation,
                            user: bot,
                            frequency: "weekly",
                            frequency_config: { "day_of_week" => day, "hour" => 12, "minute" => 0 })
          
          result = helper.format_frequency(automation)
          expect(result).to include(Date::DAYNAMES[day])
          expect(result).to include("12:00 PM UTC")
        end
      end
    end

    context "with custom_interval frequency" do
      it "formats with integer values" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "custom_interval",
                          frequency_config: { "interval_days" => 7, "hour" => 9, "minute" => 0 })
        
        expect(helper.format_frequency(automation)).to eq("Every 7 days at 09:00 AM UTC")
      end

      it "formats with string values (from form params)" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "custom_interval",
                          frequency_config: { "interval_days" => "7", "hour" => "9", "minute" => "0" })
        
        expect(helper.format_frequency(automation)).to eq("Every 7 days at 09:00 AM UTC")
      end

      it "pluralizes 'day' correctly for single day" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "custom_interval",
                          frequency_config: { "interval_days" => 1, "hour" => 9, "minute" => 0 })
        
        expect(helper.format_frequency(automation)).to eq("Every 1 day at 09:00 AM UTC")
      end

      it "pluralizes 'day' correctly for multiple days" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "custom_interval",
                          frequency_config: { "interval_days" => 14, "hour" => 9, "minute" => 0 })
        
        expect(helper.format_frequency(automation)).to eq("Every 14 days at 09:00 AM UTC")
      end
    end

    context "with unknown frequency" do
      it "returns 'Unknown frequency'" do
        automation = build(:scheduled_automation,
                          user: bot,
                          frequency: "daily")
        automation.frequency = "invalid_frequency"
        
        expect(helper.format_frequency(automation)).to eq("Unknown frequency")
      end
    end
  end

  describe "#format_time" do
    it "formats midnight correctly" do
      expect(helper.format_time(0, 0)).to eq("12:00 AM UTC")
    end

    it "formats noon correctly" do
      expect(helper.format_time(12, 0)).to eq("12:00 PM UTC")
    end

    it "formats morning time correctly" do
      expect(helper.format_time(9, 30)).to eq("09:30 AM UTC")
    end

    it "formats afternoon time correctly" do
      expect(helper.format_time(15, 45)).to eq("03:45 PM UTC")
    end

    it "formats late night time correctly" do
      expect(helper.format_time(23, 59)).to eq("11:59 PM UTC")
    end

    it "handles single digit minutes with leading zero" do
      expect(helper.format_time(10, 5)).to eq("10:05 AM UTC")
    end
  end
end

