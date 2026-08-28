require "rails_helper"

RSpec.describe Concepts::EvaluateThresholdsWorker, type: :worker do
  let!(:concept1) { create(:concept) }
  let!(:concept2) { create(:concept) }

  describe "#perform" do
    let(:evaluator1) { instance_double(Concepts::ThresholdEvaluator, call: true) }
    let(:evaluator2) { instance_double(Concepts::ThresholdEvaluator, call: true) }

    context "when concept_id is provided" do
      before do
        allow(Concepts::ThresholdEvaluator).to receive(:new).with(concept1).and_return(evaluator1)
      end

      it "evaluates threshold only for the specified concept" do
        described_class.new.perform(concept1.id)
        expect(Concepts::ThresholdEvaluator).to have_received(:new).with(concept1)
        expect(evaluator1).to have_received(:call)
      end
    end

    context "when concept_id is not provided" do
      before do
        allow(Concepts::ThresholdEvaluator).to receive(:new).with(concept1).and_return(evaluator1)
        allow(Concepts::ThresholdEvaluator).to receive(:new).with(concept2).and_return(evaluator2)
      end

      it "evaluates threshold for all concepts" do
        described_class.new.perform
        expect(Concepts::ThresholdEvaluator).to have_received(:new).with(concept1)
        expect(Concepts::ThresholdEvaluator).to have_received(:new).with(concept2)
        expect(evaluator1).to have_received(:call)
        expect(evaluator2).to have_received(:call)
      end
    end
  end
end
