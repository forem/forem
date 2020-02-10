require "rails_helper"
RSpec.describe Notifications::NotifiableActionWorker, type: :worker do
  describe "#perform" do
    let(:service) { Notifications::NotifiableAction::Send }
    let(:worker) { subject }
    let(:action) { "Published" }

    before do
      allow(service).to receive(:call)
    end

    it "calls the service when existing notifiable passed" do
      notifiable = create(:article)
      worker.perform(notifiable.id, "Article", action)
      expect(service).to have_received(:call).with(notifiable, action).once
    end

    it "doesn't call a service when notifiable doesn't exist" do
      worker.perform(Article.maximum(:id).to_i + 1, "Article", action)
      expect(service).not_to have_received(:call)
    end

    it "doesn't call a service when unexpected notifiable type passed" do
      user = create(:user)
      worker.perform(user.id, "User", "Upgraded")
      expect(service).not_to have_received(:call)
    end
  end
end
