require "rails_helper"
require "jobs/shared_examples/enqueues_job"

RSpec.describe Articles::UpdateAnalyticsJob, type: :job do
  include_examples "#enqueues_job", "articles_update_analytics", 456

  describe "#perform_now" do
    let(:article_analytics_updater_service) { class_double(Articles::AnalyticsUpdater) }

    before do
      allow(article_analytics_updater_service).to receive(:call)
    end

    context "when user_id a real user" do
      before do
        allow(User).to receive(:find_by).and_return(456)
      end

      it "calls the service" do
        described_class.perform_now(456, article_analytics_updater_service)
        expect(article_analytics_updater_service).to have_received(:call).with(456)
      end
    end

    context "when user_id not a real user" do
      before do
        allow(User).to receive(:find_by)
      end

      it "does not call the service" do
        described_class.perform_now(456, article_analytics_updater_service)
        expect(article_analytics_updater_service).not_to have_received(:call)
      end
    end
  end
end
