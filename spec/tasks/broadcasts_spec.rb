require "rails_helper"

RSpec.describe "Broadcasts tasks", type: :task do
  let(:service)    { Broadcasts::WelcomeNotification::Generator }
  let(:start_date) { service::NOTIFICATIONS_SET_LIVE_DATE }

  before do
    allow(service).to receive(:call)
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#broadcast_welcome_notification_flow" do
    it "does not call upon users created before the start_date" do
      Timecop.travel(start_date) do
        create(:user, created_at: 1.day.ago)
        Rake::Task["broadcasts:send_welcome_notification_flow"].invoke
        expect(service).not_to have_received(:call)
      end
    end

    it "call upon users created less than a week ago" do
      Timecop.travel(start_date + 1.week) do
        create_list(:user, 3, created_at: 6.days.ago)
        Rake::Task["broadcasts:send_welcome_notification_flow"].invoke
        expect(service).to have_received(:call).exactly(3)
      end
    end
  end
end
