require "rails_helper"

RSpec.describe Concepts::ThresholdEvaluator, type: :service do
  let!(:concept) { create(:concept, similarity_threshold: 0.28) }
  let!(:article1) { create(:article, published: true) }
  let!(:article2) { create(:article, published: true) }

  let!(:membership1) do
    create(:concept_membership, concept: concept, record: article1, created_at: 1.hour.ago)
  end
  let!(:membership2) do
    create(:concept_membership, concept: concept, record: article2, created_at: 1.hour.ago)
  end

  describe "#call" do
    context "when all evaluated articles are appropriate" do
      before do
        evaluator1 = instance_double(Ai::ConceptArticleEvaluator, appropriate?: true)
        evaluator2 = instance_double(Ai::ConceptArticleEvaluator, appropriate?: true)

        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept, article1).and_return(evaluator1)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept, article2).and_return(evaluator2)
      end

      it "increases the similarity threshold slightly" do
        expect do
          described_class.new(concept).call
        end.to change { concept.reload.similarity_threshold }.from(0.28).to(0.29)
      end

      it "retains all memberships" do
        described_class.new(concept).call
        expect(concept.concept_memberships.reload).to include(membership1, membership2)
      end
    end

    context "when any evaluated article is inappropriate" do
      before do
        evaluator1 = instance_double(Ai::ConceptArticleEvaluator, appropriate?: true)
        evaluator2 = instance_double(Ai::ConceptArticleEvaluator, appropriate?: false)

        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept, article1).and_return(evaluator1)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept, article2).and_return(evaluator2)
      end

      it "decreases the similarity threshold to be more strict" do
        expect do
          described_class.new(concept).call
        end.to change { concept.reload.similarity_threshold }.from(0.28).to(0.27)
      end

      it "deletes the inappropriate concept membership" do
        described_class.new(concept).call
        expect(ConceptMembership.exists?(membership2.id)).to be(false)
        expect(ConceptMembership.exists?(membership1.id)).to be(true)
      end
    end

    context "when concept threshold is initially nil" do
      let(:concept_nil_threshold) { create(:concept, similarity_threshold: nil) }

      before do
        create(:concept_membership, concept: concept_nil_threshold, record: article1, created_at: 1.hour.ago)
        evaluator = instance_double(Ai::ConceptArticleEvaluator, appropriate?: true)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept_nil_threshold, article1).and_return(evaluator)
      end

      it "falls back to default threshold (0.28) and increases it" do
        described_class.new(concept_nil_threshold).call
        expect(concept_nil_threshold.reload.similarity_threshold).to eq(0.29)
      end
    end

    context "when threshold reaches upper boundary (MAX_THRESHOLD)" do
      let(:concept_max) { create(:concept, similarity_threshold: 0.60) }

      before do
        create(:concept_membership, concept: concept_max, record: article1, created_at: 1.hour.ago)
        evaluator = instance_double(Ai::ConceptArticleEvaluator, appropriate?: true)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept_max, article1).and_return(evaluator)
      end

      it "clamps threshold at MAX_THRESHOLD (0.60)" do
        described_class.new(concept_max).call
        expect(concept_max.reload.similarity_threshold).to eq(0.60)
      end
    end

    context "when threshold reaches lower boundary (MIN_THRESHOLD)" do
      let(:concept_min) { create(:concept, similarity_threshold: 0.10) }

      before do
        create(:concept_membership, concept: concept_min, record: article1, created_at: 1.hour.ago)
        evaluator = instance_double(Ai::ConceptArticleEvaluator, appropriate?: false)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept_min, article1).and_return(evaluator)
      end

      it "clamps threshold at MIN_THRESHOLD (0.10)" do
        described_class.new(concept_min).call
        expect(concept_min.reload.similarity_threshold).to eq(0.10)
      end
    end

    context "when there are no memberships within the lookback period" do
      before do
        create(:concept_membership, concept: concept, record: create(:article), created_at: 5.hours.ago)
        membership1.update_column(:created_at, 5.hours.ago)
        membership2.update_column(:created_at, 5.hours.ago)
      end

      it "leaves the threshold unchanged" do
        expect do
          described_class.new(concept, lookback_period: 3.hours).call
        end.not_to change { concept.reload.similarity_threshold }
      end
    end

    context "when AI evaluation returns nil (e.g. API error)" do
      before do
        evaluator1 = instance_double(Ai::ConceptArticleEvaluator, appropriate?: nil)
        allow(Ai::ConceptArticleEvaluator).to receive(:new).with(concept, article1).and_return(evaluator1)
        membership2.destroy
      end

      it "does not alter the threshold" do
        expect do
          described_class.new(concept).call
        end.not_to change { concept.reload.similarity_threshold }
      end
    end
  end
end
