require "rails_helper"

RSpec.describe Ai::ConceptArticleEvaluator, type: :service do
  let(:concept) { create(:concept, name: "Ruby on Rails", description: "Web framework in Ruby.") }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
  end

  describe "#appropriate?" do
    context "when AI responds with YES" do
      before do
        allow(ai_client).to receive(:call).and_return("YES")
      end

      it "returns true" do
        evaluator = described_class.new(concept, article)
        expect(evaluator.appropriate?).to be(true)
      end

      it "builds a prompt with concept and article details" do
        evaluator = described_class.new(concept, article)
        prompt = evaluator.__send__(:build_prompt)
        expect(prompt).to include("Ruby on Rails")
        expect(prompt).to include("Web framework in Ruby.")
        expect(prompt).to include(article.title)
      end
    end

    context "when AI responds with NO" do
      before do
        allow(ai_client).to receive(:call).and_return("NO")
      end

      it "returns false" do
        evaluator = described_class.new(concept, article)
        expect(evaluator.appropriate?).to be(false)
      end
    end

    context "when AI response is ambiguous or blank" do
      before do
        allow(ai_client).to receive(:call).and_return("")
      end

      it "returns nil" do
        evaluator = described_class.new(concept, article)
        expect(evaluator.appropriate?).to be_nil
      end
    end

    context "when AI raises an error" do
      before do
        allow(ai_client).to receive(:call).and_raise(StandardError.new("API Error"))
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error and returns nil" do
        evaluator = described_class.new(concept, article)
        expect(evaluator.appropriate?).to be_nil
        expect(Rails.logger).to have_received(:error).with(/Ai::ConceptArticleEvaluator/)
      end
    end
  end

  describe "#appropriate? with Jev selected" do
    before { enable_jev_for(:concept_article_relevance) }

    it "returns true for a confident fit" do
      requests = stub_jev(fits_concept: 0.9)

      expect(described_class.new(concept, article).appropriate?).to be(true)
      expect(Ai::Base).not_to have_received(:new)
      expect(requests.first[:state][:concept]).to eq(name: "Ruby on Rails", description: "Web framework in Ruby.")
    end

    it "returns false for a confident miss" do
      stub_jev(fits_concept: 0.1)

      expect(described_class.new(concept, article).appropriate?).to be(false)
    end

    it "abstains with nil when uncertain so the threshold does not move" do
      stub_jev(fits_concept: 0.5)

      expect(described_class.new(concept, article).appropriate?).to be_nil
    end
  end
end
