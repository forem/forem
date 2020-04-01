require "rails_helper"

RSpec.describe "Broadcasts tasks" do
  let(:service) { Broadcasts::WelcomeNotification::Generator }

  before do
    allow(service).to receive(:call)
    Rake::Task.clear
    PracticalDeveloper::Application.load_tasks
  end

  describe "#broadcast_welcome_notification_flow" do
    it "does not call upon users created more than a week away" do
      create(:user, :with_identity, identities: ["github"], created_at: 8.days.ago)
      Rake::Task["broadcast_welcome_notification_flow"].invoke
      expect(service).not_to have_received(:call)
    end

    it "call upon users created less than a week ago" do
      create_list(:user, 3, :with_identity, identities: ["github"], created_at: 1.day.ago)
      Rake::Task["broadcast_welcome_notification_flow"].invoke
      expect(service).to have_received(:call).exactly(3)
    end
  end
end
