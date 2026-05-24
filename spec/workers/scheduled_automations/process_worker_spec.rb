require "rails_helper"

RSpec.describe ScheduledAutomations::ProcessWorker, type: :worker do
  describe "#perform" do
    let(:bot) { create(:user, type_of: :community_bot) }
    let(:badge) { create(:badge, slug: "warm-welcome", title: "Warm Welcome") }

    context "when warm welcome badge exists" do
      before do
        badge # Create the badge
        bot # Ensure bot exists before perform is called
      end

      context "when automation does not exist" do
        it "creates the automation automatically" do
          expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)

          described_class.new.perform

          automation = ScheduledAutomation.find_by(action: "award_warm_welcome_badge")
          expect(automation).to be_present
          expect(automation.frequency).to eq("weekly")
          expect(automation.frequency_config["day_of_week"]).to eq(5) # Friday
          expect(automation.frequency_config["hour"]).to eq(9)
          expect(automation.frequency_config["minute"]).to eq(0)
          expect(automation.action).to eq("award_warm_welcome_badge")
          expect(automation.service_name).to eq("warm_welcome_badge")
          expect(automation.enabled).to be(true)
          expect(automation.state).to eq("active")
          expect(automation.user).to eq(bot)
        end

        it "schedules next run for Friday at 9 AM" do
          expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)

          described_class.new.perform

          automation = ScheduledAutomation.find_by(action: "award_warm_welcome_badge")
          expect(automation).to be_present
          expect(automation.next_run_at).to be_present
          expect(automation.next_run_at.wday).to eq(5) # Friday
          expect(automation.next_run_at.hour).to eq(9)
        end

        context "when no community bot exists" do
          before do
            bot.destroy
          end

          it "does not create automation and logs warning" do
            expect(Rails.logger).to receive(:warn).with(/No community bot found/)
            expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)

            described_class.new.perform

            expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)
          end
        end
      end

      context "when automation already exists" do
        let!(:existing_automation) do
          create(:scheduled_automation,
                 user: bot,
                 action: "award_warm_welcome_badge",
                 service_name: "warm_welcome_badge")
        end

        it "does not create a duplicate automation" do
          expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(1)

          described_class.new.perform

          expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(1)
        end
      end
    end

    context "when warm welcome badge does not exist" do
      before do
        badge.destroy if badge.persisted?
      end

      it "does not create automation" do
        expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)

        described_class.new.perform

        expect(ScheduledAutomation.where(action: "award_warm_welcome_badge").count).to eq(0)
      end
    end

    context "when executing due automations" do
      let(:bot) { create(:user, type_of: :community_bot) }
      let(:automation) do
        create(:scheduled_automation,
               user: bot,
               service_name: "test_service",
               action: "create_draft",
               frequency: "daily",
               frequency_config: { "hour" => 9, "minute" => 0 },
               next_run_at: 1.hour.ago, # Any time in the past is due
               enabled: true,
               state: "active")
      end

      before do
        allow(ScheduledAutomations::Executor).to receive(:call).and_return(
          double(success?: true, article: nil, error_message: nil),
        )
      end

      it "executes automations that are due" do
        automation
        expect(ScheduledAutomations::Executor).to receive(:call).with(automation)

        described_class.new.perform
      end

      it "does not execute automations that are scheduled for the future" do
        automation # due automation
        future_automation = create(:scheduled_automation,
                                   user: bot,
                                   service_name: "future_service",
                                   action: "create_draft",
                                   frequency: "daily",
                                   frequency_config: { "hour" => 9, "minute" => 0 },
                                   next_run_at: 1.hour.from_now,
                                   enabled: true,
                                   state: "active")

        # Due automation should be called
        expect(ScheduledAutomations::Executor).to receive(:call).with(automation)
        # Future automation should NOT be called
        expect(ScheduledAutomations::Executor).not_to receive(:call).with(future_automation)

        described_class.new.perform
      end

      it "executes automations even if they are very past due" do
        very_past_due_automation = create(:scheduled_automation,
                                          user: bot,
                                          service_name: "past_due_service",
                                          action: "create_draft",
                                          frequency: "daily",
                                          frequency_config: { "hour" => 9, "minute" => 0 },
                                          next_run_at: 1.month.ago,
                                          enabled: true,
                                          state: "active")

        expect(ScheduledAutomations::Executor).to receive(:call).with(very_past_due_automation)

        described_class.new.perform
      end
    end
  end
end
