require "rails_helper"

RSpec.describe Notifications::MilestoneJob do
  include_examples "#enqueues_job", "send_milestone_notification", {}

  describe "#perform_now" do
    let(:milestone_service) { double }
    let(:article) { double }

    before do
      allow(milestone_service).to receive(:call)
    end

    specify "fetch article id only if :article_id key in hash " do
      allow(Article).to receive(:find_by)
      described_class.perform_now("Reaction", 456, milestone_service)
      expect(Article).to have_received(:find_by).with(id: 456)
    end

    describe "When it does not find article from id" do
      it "does not call the service" do
        allow(Article).to receive(:find_by)
        described_class.perform_now("Reaction", 456, milestone_service)
        expect(milestone_service).not_to have_received(:call)
      end
    end

    describe "When finds article from id" do
      it "calls the service" do
        allow(Article).to receive(:find_by).and_return(article)
        described_class.perform_now("Reaction", 456, milestone_service)
        expect(milestone_service).to have_received(:call).with("Reaction", article)
      end
    end
  end
end
