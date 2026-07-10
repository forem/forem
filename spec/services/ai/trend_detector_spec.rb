require "rails_helper"

RSpec.describe Ai::TrendDetector do
  let(:detector) { described_class.new }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    allow(Trends::GenerateCoverImageWorker).to receive(:perform_async)
    allow(Tag).to receive(:direct).and_return(Tag.none)
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
        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 3)
        end.to change(Trend, :count).by(1)
          .and change(TrendMembership, :count).by(3)

        trend = Trend.last
        expect(trend.name).to eq("Emergent Ruby Patterns")
        expect(trend.description).to eq("A cluster of discussions focused on Ruby patterns and updates.")
        expect(trend.key_questions).to eq(["What is Ruby 3.4 bringing?", "How do these patterns compare to python?"])
        expect(trend.articles).to contain_exactly(article1, article2, article3)

        expect(Trends::GenerateCoverImageWorker).to have_received(:perform_async).with(trend.id)
      end
    end

    context "when some qualifying articles are excluded from the first-pass sample limit" do
      before do
        # Stub the first-pass limit to only select the top 2 articles (article2 and article3 by score)
        allow(Article).to receive(:published).and_wrap_original do |m, *args|
          relation = m.call(*args)
          class << relation
            def limit(limit_val)
              if limit_val == 1000 && to_sql.exclude?("computed_distance")
                super(2)
              else
                super(limit_val)
              end
            end
          end
          relation
        end
      end

      it "includes the excluded article in the second pass and marks it as a trend member" do
        # min_articles: 2, so article2 and article3 (score 25, 30) form a cluster of size 2, creating the trend.
        # article1 (score 20) is excluded from the first-pass limit(2) but should be caught by the second pass.
        expect do
          detector.call(min_articles: 2, min_score: 10, min_unique_authors: 2)
        end.to change(Trend, :count).by(1)
          .and change(TrendMembership, :count).by(3)

        trend = Trend.last
        expect(trend.articles).to contain_exactly(article1, article2, article3)
      end
    end

    context "when filtering by article score" do
      it "excludes articles with score below min_score" do
        # If min_score is 22, article1 (score 20) is excluded.
        # This leaves only article2 and article3 (count 2), which is below min_articles (3).
        # Thus, no trend should be created.
        expect do
          detector.call(min_articles: 3, min_score: 22)
        end.not_to change(Trend, :count)
      end
    end

    context "when filtering by cluster size (min_articles)" do
      it "does not create a trend if cluster size is below min_articles" do
        # 3 articles in cluster, min_articles is set to 4
        expect do
          detector.call(min_articles: 4, min_score: 10)
        end.not_to change(Trend, :count)
      end
    end

    context "when filtering by author diversity (min_unique_authors)" do
      it "does not create a trend if the number of unique authors is below min_unique_authors" do
        # Associate the same user to all three articles
        user = create(:user)
        article1.update!(user: user)
        article2.update!(user: user)
        article3.update!(user: user)

        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 2)
        end.not_to change(Trend, :count)
      end

      it "creates a trend if the number of unique authors matches or exceeds min_unique_authors" do
        # Default behavior where articles have different users
        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 3)
        end.to change(Trend, :count).by(1)
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
        # updates existing_trend, doesn't create new
        expect do
          detector.call(min_articles: 3, min_score: 10, match_threshold: 0.88, min_unique_authors: 3)
        end.not_to change(Trend, :count)
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

      before do
        create(:trend,
               name: "Existing Trend",
               description: "Old description",
               centroid_embedding: embedding_moderate,
               first_observed_at: 2.days.ago,
               last_observed_at: 2.days.ago)
      end

      it "updates the existing trend if match_threshold is set to 0.88" do
        # Passing min_unique_authors: 3 to satisfy diversity with 3 test articles
        expect do
          detector.call(min_articles: 3, min_score: 10, match_threshold: 0.88, min_unique_authors: 3)
        end.not_to change(Trend, :count)
      end

      it "creates a new trend under the default match_threshold of 0.97" do
        # Passing min_unique_authors: 3 to satisfy diversity with 3 test articles
        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 3)
        end.to change(Trend, :count).by(1)
      end
    end

    context "when using default min_unique_authors" do
      it "does not create a trend if there are only 3 unique authors" do
        expect do
          detector.call(min_articles: 3, min_score: 10)
        end.not_to change(Trend, :count)
      end

      it "creates a trend if there are 4 unique authors" do
        embedding4 = Array.new(768, 0.105)
        create(:article, published: true, score: 15, semantic_embedding: embedding4)

        expect do
          detector.call(min_articles: 4, min_score: 10)
        end.to change(Trend, :count).by(1)
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
        expect do
          detector.call
        end.not_to change(Trend, :count)
      end

      it "uses 0.89 for similarity_threshold and 0.97 for match_threshold by default" do
        allow(detector).to receive(:detect_trends_for)
        detector.call
        expect(detector).to have_received(:detect_trends_for).with(
          tag: nil,
          days_lookback: 7,
          similarity_threshold: 0.89,
          match_threshold: 0.97,
          min_articles: 10,
          min_score: 5,
          min_unique_authors: 4
        ).at_least(:once)
      end
    end

    context "with per-tag trend detection" do
      before do
        allow(Tag).to receive(:direct).and_return(Tag.where(name: %w[ruby python]))
      end

      let!(:tag_ruby) { create(:tag, name: "ruby", hotness_score: 100) }
      let!(:tag_python) { create(:tag, name: "python", hotness_score: 50) }

      let!(:ruby_article1) do
        create(:article, published: true, score: 20, semantic_embedding: embedding1, tag_list: "ruby")
      end
      let!(:ruby_article2) do
        create(:article, published: true, score: 25, semantic_embedding: embedding2, tag_list: "ruby")
      end
      let!(:ruby_article3) do
        create(:article, published: true, score: 30, semantic_embedding: embedding3, tag_list: "ruby")
      end

      let!(:python_article1) do
        create(:article, published: true, score: 20, semantic_embedding: embedding1, tag_list: "python")
      end
      let!(:python_article2) do
        create(:article, published: true, score: 25, semantic_embedding: embedding2, tag_list: "python")
      end

      it "detects trends for the hottest tags that satisfy min_articles" do
        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 3)
        end.to change(Trend, :count).by(2) # 1 global trend and 1 ruby trend

        ruby_trend = Trend.find_by(tag: tag_ruby)
        global_trend = Trend.find_by(tag: nil)

        expect(ruby_trend).to be_present
        expect(global_trend).to be_present
        expect(Trend.find_by(tag: tag_python)).to be_nil

        expect(ruby_trend.articles).to contain_exactly(ruby_article1, ruby_article2, ruby_article3)
        expect(global_trend.articles).to contain_exactly(
          article1, article2, article3,
          ruby_article1, ruby_article2, ruby_article3,
          python_article1, python_article2
        )
      end

      it "does not match trends across different tags" do
        existing_ruby_trend = create(:trend, name: "Old Ruby", centroid_embedding: embedding1, tag: tag_ruby,
                                             first_observed_at: 2.days.ago, last_observed_at: 2.days.ago)

        expect do
          detector.call(min_articles: 3, min_score: 10, min_unique_authors: 3)
        end.to change(Trend, :count).by(1) # Only creates global trend

        expect(existing_ruby_trend.reload.name).to eq("Emergent Ruby Patterns")
      end
    end
  end
end
