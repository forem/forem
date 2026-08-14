require "rails_helper"

RSpec.describe IdentifyTrendsWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let(:detector) { instance_double(Ai::TrendDetector) }

    before do
      allow(Ai::TrendDetector).to receive(:new).and_return(detector)
      allow(detector).to receive(:call)
    end

    context "when Ai::Base::DEFAULT_KEY is blank" do
      before do
        stub_const("Ai::Base::DEFAULT_KEY", "")
      end

      it "does not invoke TrendDetector" do
        worker.perform
        expect(Ai::TrendDetector).not_to have_received(:new)
      end
    end

    context "when Ai::Base::DEFAULT_KEY is present" do
      before do
        stub_const("Ai::Base::DEFAULT_KEY", "dummy_key")
      end

      it "invokes TrendDetector" do
        worker.perform
        expect(Ai::TrendDetector).to have_received(:new)
        expect(detector).to have_received(:call)
      end
    end
  end
end
