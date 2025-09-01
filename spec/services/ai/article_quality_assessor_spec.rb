require "rails_helper"

RSpec.describe Ai::ArticleQualityAssessor, type: :service do
  let(:user) { create(:user, :trusted) }
  let(:spam_user) { create(:user, :spam) }
  let(:ai_client) { instance_double(Ai::Base) }

  before do
    allow(Ai::Base).to receive(:new).and_return(ai_client)
    # Mock the community description settings
    allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return(nil)
    allow(Settings::Community).to receive(:community_description).and_return("A community for developers to share knowledge and experiences.")
  end

  describe "#assess" do
    context "when no articles are provided" do
      it "returns nil for both best and worst" do
        result = described_class.new([]).assess
        expect(result).to eq({ best: nil, worst: nil })
      end
    end

    context "when only one article is provided" do
      let(:article) { create(:article, user: user) }

      it "returns the same article for both best and worst" do
        result = described_class.new([article]).assess
        expect(result).to eq({ best: article, worst: article })
      end
    end

    context "when multiple articles are provided" do
      let!(:high_quality_article) do
        create(:article,
               user: user,
               title: "How to Build a Great Community: A Comprehensive Guide",
               body_markdown: "---\ntitle: How to Build a Great Community: A Comprehensive Guide\npublished: true\n---\n\nThis is a detailed tutorial with code examples.\n\n```ruby\ndef hello_world\n  puts 'Hello, World!'\nend\n```\n\nThis guide will help you understand the fundamentals.",
               score: 50,
               comments_count: 10,
               public_reactions_count: 25,
               reading_time: 8)
      end

      let!(:low_quality_article) do
        create(:article,
               user: spam_user,
               title: "BUY NOW!!!",
               body_markdown: "---\ntitle: BUY NOW!!!\npublished: true\n---\n\nCLICK HERE TO GET AMAZING DEALS!!! LIMITED TIME OFFER!!! [Buy Now](https://spam-site.com) [Sign Up](https://another-spam.com) !!!",
               score: 5,
               comments_count: 1,
               public_reactions_count: 2,
               reading_time: 1)
      end

      let!(:medium_quality_article) do
        create(:article,
               user: create(:user),
               title: "Some Article",
               body_markdown: "---\ntitle: Some Article\npublished: true\n---\n\nThis is a regular article with some content.",
               score: 20,
               comments_count: 5,
               public_reactions_count: 10,
               reading_time: 3)
      end

      let(:articles) { [high_quality_article, low_quality_article, medium_quality_article] }

      context "when AI responds successfully" do
        before do
          allow(ai_client).to receive(:call).and_return("1,2") # Article 1 is best, Article 2 is worst
        end

        it "uses AI to identify best and worst articles" do
          result = described_class.new(articles).assess

          expect(result[:best]).to eq(high_quality_article)
          expect(result[:worst]).to eq(low_quality_article)
        end

        it "calls the AI with a properly formatted prompt" do
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include("Analyze the following 3 articles")
            expect(prompt).to include("Community Context:")
            expect(prompt).to include("A community for developers to share knowledge and experiences.")
            expect(prompt).to include("Article 1:")
            expect(prompt).to include("Article 2:")
            expect(prompt).to include("Article 3:")
            expect(prompt).to include("Authentic Human Connection")
            expect(prompt).to include("Community Relevance")
            expect(prompt).to include("Respond with only the two numbers separated by a comma:")
            "1,2"
          end

          described_class.new(articles).assess
        end
      end

      context "when AI responds with different indices" do
        before do
          allow(ai_client).to receive(:call).and_return("3,1") # Article 3 is best, Article 1 is worst
        end

        it "correctly maps AI response to articles" do
          result = described_class.new(articles).assess

          expect(result[:best]).to eq(medium_quality_article)
          expect(result[:worst]).to eq(high_quality_article)
        end
      end

      context "when internal_content_description_spec is available" do
        before do
          allow(Settings::RateLimit).to receive(:internal_content_description_spec).and_return("A specialized community for Ruby developers")
          allow(ai_client).to receive(:call).and_return("1,2")
        end

        it "uses the internal content description in the prompt" do
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include("Community Context:")
            expect(prompt).to include("A specialized community for Ruby developers")
            expect(prompt).not_to include("A community for developers to share knowledge and experiences.")
            "1,2"
          end

          described_class.new(articles).assess
        end
      end

      context "when subforem_id is provided" do
        before do
          allow(Settings::RateLimit).to receive(:internal_content_description_spec).with(subforem_id: 123).and_return("Subforem-specific description")
          allow(ai_client).to receive(:call).and_return("1,2")
        end

        it "uses subforem-specific community description" do
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include("Community Context:")
            expect(prompt).to include("Subforem-specific description")
            expect(prompt).not_to include("A community for developers to share knowledge and experiences.")
            "1,2"
          end

          described_class.new(articles, subforem_id: 123).assess
        end
      end

      context "when AI response is malformed" do
        before do
          allow(ai_client).to receive(:call).and_return("invalid response")
        end

        it "falls back to score-based assessment" do
          result = described_class.new(articles).assess

          # Should fall back to highest score = best, lowest score = worst
          expect(result[:best]).to be_nil
          expect(result[:worst]).to be_nil
        end
      end

      context "when AI response has invalid indices" do
        before do
          allow(ai_client).to receive(:call).and_return("5,10") # Invalid indices
        end

        it "falls back to score-based assessment" do
          result = described_class.new(articles).assess

          # Should fall back to highest score = best, lowest score = worst
          expect(result[:best]).to be_nil
          expect(result[:worst]).to be_nil
        end
      end

      context "when AI raises an error" do
        before do
          allow(ai_client).to receive(:call).and_raise(StandardError, "API Error")
        end

        it "falls back to score-based assessment" do
          result = described_class.new(articles).assess

          # Should fall back to highest score = best, lowest score = worst
          expect(result[:best]).to be_nil
          expect(result[:worst]).to be_nil
        end

        it "logs the error" do
          allow(Rails.logger).to receive(:error)

          described_class.new(articles).assess

          expect(Rails.logger).to have_received(:error).with(/Article Quality Assessment failed/)
        end
      end
    end
  end
end
