require "rails_helper"

RSpec.describe Notifications::RemoveAllByActionJob, type: :job do
  include_examples "#enqueues_job", "remove_all_by_action_notifications", {}

  describe "#perform_now" do
    let(:remove_all_by_action_service) { double }
    let(:article) { create(:article) }

    before do
      allow(remove_all_by_action_service).to receive(:call)
    end

    it "calls the service" do
      described_class.perform_now(article.id, "Article", "Published", remove_all_by_action_service)
      expect(remove_all_by_action_service).to have_received(:call).with([article.id], "Article", "Published")
    end
  end
end
