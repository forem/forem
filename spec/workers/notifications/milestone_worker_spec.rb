require "rails_helper"

RSpec.describe Notifications::MilestoneWorker, type: :worker do
  describe "#perform_now" do
    let(:milestone_service) { double }
    let(:article) { double }
    let(:worker) { subject }

    before do
      allow(Notifications::Milestone::Send).to receive(:call)
    end

    specify "fetch article id only if :article_id key in hash" do
      allow(Article).to receive(:find_by)
      worker.perform("Reaction", 456)
      expect(Article).to have_received(:find_by).with(id: 456)
    end

    describe "When it does not find article from id" do
      it "does not call the service" do
        allow(Article).to receive(:find_by)
        worker.perform("Reaction", 456)
        expect(Notifications::Milestone::Send).not_to have_received(:call)
      end
    end

    describe "When finds article from id" do
      it "calls the service" do
        allow(Article).to receive(:find_by).and_return(article)
        worker.perform("Reaction", 456)
        expect(Notifications::Milestone::Send).to have_received(:call).with("Reaction", article)
      end
    end
  end
end
