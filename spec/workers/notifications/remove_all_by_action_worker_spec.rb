require "rails_helper"

RSpec.describe Notifications::RemoveAllByActionWorker, type: :worker do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:user) { create(:user) }
    let(:worker) { subject }
    let(:service) { Notifications::RemoveAllByAction }

    before do
      allow(service).to receive(:call)
    end

    it "calls the service" do
      worker.perform(article.id, "Article", "Published")
      expect(service).to have_received(:call).with([article.id], "Article", "Published")
    end

    it "doesn't call a service when notifiable id doesn't exist" do
      worker.perform(Article.maximum(:id).to_i + 1, "Article", "Upgraded")
      expect(service).not_to have_received(:call)
    end

    it "doesn't call a service when unexpected notifiable type passed" do
      worker.perform(user.id, "User", "Upgraded")
      expect(service).not_to have_received(:call)
    end
  end
end
