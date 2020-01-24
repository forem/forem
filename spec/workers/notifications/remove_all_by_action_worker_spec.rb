require "rails_helper"

RSpec.describe Notifications::RemoveAllByActionWorker, type: :worker do
  describe "#perform" do
    let(:article) { create(:article) }
    let(:worker) { subject }

    before do
      allow(Notifications::RemoveAllByAction).to receive(:call)
    end

    it "calls the service" do
      worker.perform(article.id, "Article", "Published")
      expect(Notifications::RemoveAllByAction).to have_received(:call).with([article.id], "Article", "Published")
    end
  end
end
