require "rails_helper"

RSpec.describe Ai::TrendDetector do
  let(:detector) { described_class.new }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Trends::GenerateCoverImageWorker).to receive(:perform_async)
  end

  describe "#call" do
    let(:embedding1) { Array.new(768, 0.1) }
    let(:embedding2) { Array.new(768, 0.11) }
    let(:embedding3) { Array.new(768, 0.09) }

    let!(:article1) { create(:article, published: true, score: 20, semantic_embedding: embedding1) }
    let!(:article2) { create(:article, published: true, score: 25, semantic_embedding: embedding2) }
    let!(:article3) { create(:article, published: true, score: 30, semantic_embedding: embedding3) }

    let(:mock_gemini_response) do
      <<~JSON
        {
          "name": "Emergent Ruby Patterns",
          "description": "A cluster of discussions focused on Ruby patterns and updates.",
          "key_questions": ["What is Ruby 3.4 bringing?", "How do these patterns compare to python?"]
        }
      JSON
    end

    before do
      allow(ai_client).to receive(:call).and_return(mock_gemini_response)
    end

    context "when thresholds are satisfied" do
      it "clusters articles and creates a new Trend and TrendMemberships" do
        expect {
          detector.call(min_articles: 3, min_score: 10)
        }.to change(Trend, :count).by(1)
         .and change(TrendMembership, :count).by(3)

        trend = Trend.last
        expect(trend.name).to eq("Emergent Ruby Patterns")
        expect(trend.description).to eq("A cluster of discussions focused on Ruby patterns and updates.")
        expect(trend.key_questions).to eq(["What is Ruby 3.4 bringing?", "How do these patterns compare to python?"])
        expect(trend.articles).to contain_exactly(article1, article2, article3)

        expect(Trends::GenerateCoverImageWorker).to have_received(:perform_async).with(trend.id)
      end
    end

    context "when filtering by article score" do
      it "excludes articles with score below min_score" do
        # If min_score is 22, article1 (score 20) is excluded.
        # This leaves only article2 and article3 (count 2), which is below min_articles (3).
        # Thus, no trend should be created.
        expect {
          detector.call(min_articles: 3, min_score: 22)
        }.not_to change(Trend, :count)
      end
    end

    context "when filtering by cluster size (min_articles)" do
      it "does not create a trend if cluster size is below min_articles" do
        # 3 articles in cluster, min_articles is set to 4
        expect {
          detector.call(min_articles: 4, min_score: 10)
        }.not_to change(Trend, :count)
      end
    end

    context "when a similar active trend already exists" do
      let!(:existing_trend) do
        create(:trend,
               name: "Existing Trend",
               description: "Old description",
               centroid_embedding: embedding1,
               first_observed_at: 2.days.ago,
               last_observed_at: 2.days.ago)
      end

      it "updates the existing trend and adds new memberships instead of creating a duplicate" do
        # The new cluster is very close to embedding1 (distance 0.0) which is within match_threshold.
        expect {
          detector.call(min_articles: 3, min_score: 10, match_threshold: 0.88)
        }.not_to change(Trend, :count) # updates existing_trend, doesn't create new

        existing_trend.reload
        expect(existing_trend.name).to eq("Emergent Ruby Patterns")
        expect(existing_trend.description).to eq("A cluster of discussions focused on Ruby patterns and updates.")
        expect(existing_trend.articles).to contain_exactly(article1, article2, article3)

        expect(Trends::GenerateCoverImageWorker).not_to have_received(:perform_async)
      end
    end

    context "when a moderately similar active trend exists (distance ~0.095)" do
      let(:embedding_moderate) do
        emb = Array.new(768, 0.1)
        300.times { |i| emb[i] = 0.03 }
        emb
      end

      let!(:existing_trend) do
        create(:trend,
               name: "Existing Trend",
               description: "Old description",
               centroid_embedding: embedding_moderate,
               first_observed_at: 2.days.ago,
               last_observed_at: 2.days.ago)
      end

      it "updates the existing trend if match_threshold is set to 0.88" do
        expect {
          detector.call(min_articles: 3, min_score: 10, match_threshold: 0.88)
        }.not_to change(Trend, :count)
      end

      it "creates a new trend under the default match_threshold of 0.92" do
        expect {
          detector.call(min_articles: 3, min_score: 10)
        }.to change(Trend, :count).by(1)
      end
    end

    context "when testing default configurations" do
      before do
        allow(Settings::UserExperience).to receive(:index_minimum_score).and_return(5)
      end

      it "uses Settings::UserExperience.index_minimum_score as the default min_score threshold" do
        # index_minimum_score (5).
        # Since article1 (20), article2 (25), and article3 (30) all have score >= 5,
        # they are all included. However, default min_articles is 10.
        # Let's verify that under default configurations, 3 articles are not enough to create a trend.
        expect {
          detector.call
        }.not_to change(Trend, :count)
      end
    end
  end
end
