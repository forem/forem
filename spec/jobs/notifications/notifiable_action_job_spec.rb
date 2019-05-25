require "rails_helper"

RSpec.describe Notifications::NotifiableActionJob, type: :job do
  include_examples "#enqueues_job", "send_notifiable_action_notification", 5

  describe "#perform_now" do
    let(:service) { double }

    before do
      allow(service).to receive(:call)
    end

    it "calls the service when existing notifiable passed" do
      notifiable = create(:article)
      described_class.perform_now(notifiable.id, "Article", "Published", service)
      expect(service).to have_received(:call).with(notifiable, "Published").once
    end

    it "doesn't call a service when notifiable doesn't exist" do
      described_class.perform_now(Article.maximum(:id).to_i + 1, "Article", "Published", service)
      expect(service).not_to have_received(:call)
    end

    it "doesn't call a service when unexpected notifiable type passed" do
      user = create(:user)
      described_class.perform_now(user.id, "User", "Upgraded", service)
      expect(service).not_to have_received(:call)
    end
  end
end
