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

      context "when articles have trustworthiness credentials" do
        let(:verified_org) { create(:organization, verified: true) }
        let(:premium_user) { create(:user) }
        let!(:trusted_article) do
          allow(premium_user).to receive(:base_subscriber?).and_return(true)
          create(:article, user: premium_user, organization: verified_org, title: "Highly Trustworthy Article")
        end
        let(:articles) { [trusted_article, low_quality_article] }

        before do
          allow(ai_client).to receive(:call).and_return("1,2")
        end

        it "includes the author trustworthiness profile in the prompt text" do
          expect(ai_client).to receive(:call) do |prompt|
            expect(prompt).to include("Author/Publisher Background:")
            expect(prompt).to include("published by a verified organization")
            expect(prompt).to include("written by a DEV++ subscriber")
            "1,2"
          end

          described_class.new(articles).assess
        end
      end
    end
  end

  describe "#author_trustworthiness_profile" do
    let(:assessor) { described_class.new([]) }

    context "when user is nil" do
      it "returns nil" do
        article = instance_double(Article, user: nil)
        expect(assessor.send(:author_trustworthiness_profile, article)).to be_nil
      end
    end

    context "when user has no trustworthiness credentials" do
      it "returns nil" do
        regular_user = instance_double(User, base_subscriber?: false, trusted?: false, score: 0)
        article = instance_double(Article, user: regular_user, organization: nil)
        expect(assessor.send(:author_trustworthiness_profile, article)).to be_nil
      end
    end

    context "when article is from a verified organization" do
      it "includes the verified organization factor in the profile" do
        org = instance_double(Organization, verified?: true)
        regular_user = instance_double(User, base_subscriber?: false, trusted?: false, score: 0)
        article = instance_double(Article, user: regular_user, organization: org)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("published by a verified organization")
        expect(profile).to include("err on the side of treating this article as good quality")
      end
    end

    context "when user is a DEV++ subscriber" do
      it "includes the DEV++ subscriber factor in the profile" do
        dev_user = instance_double(User, base_subscriber?: true, trusted?: false, score: 0)
        article = instance_double(Article, user: dev_user, organization: nil)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("written by a DEV++ subscriber")
      end
    end

    context "when user is a trusted member" do
      it "includes the trusted member factor in the profile" do
        trusted_user = instance_double(User, base_subscriber?: false, trusted?: true, score: 0)
        article = instance_double(Article, user: trusted_user, organization: nil)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("written by a trusted member of the community")
      end
    end

    context "when user has high scores" do
      it "handles established user score (>100)" do
        reputable_user = instance_double(User, base_subscriber?: false, trusted?: false, score: 150)
        article = instance_double(Article, user: reputable_user, organization: nil)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("written by an established user with a solid reputation (user score: 150)")
      end

      it "handles exceptionally reputable user score (>500)" do
        super_user = instance_double(User, base_subscriber?: false, trusted?: false, score: 600)
        article = instance_double(Article, user: super_user, organization: nil)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("written by an exceptionally reputable user (user score: 600)")
      end
    end

    context "when multiple criteria are met" do
      it "combines them into a sentence" do
        org = instance_double(Organization, verified?: true)
        super_user = instance_double(User, base_subscriber?: true, trusted?: true, score: 600)
        article = instance_double(Article, user: super_user, organization: org)

        profile = assessor.send(:author_trustworthiness_profile, article)
        expect(profile).to include("published by a verified organization, written by a DEV++ subscriber, written by a trusted member of the community, and written by an exceptionally reputable user (user score: 600)")
      end
    end
  end
end
