require "rails_helper"

RSpec.describe Articles::QualityReactionWorker, type: :worker do
  let(:mascot_user) { create(:user, :trusted, username: "mascot") }
  let(:user) { create(:user, :trusted) }
  let(:spam_user) { create(:user, :spam) }

  before do
    allow(User).to receive(:mascot_account).and_return(mascot_user)
    # Mock discoverable subforems - only return subforem 1 since that's where our test articles are
    allow(Subforem).to receive(:cached_discoverable_ids).and_return([1])
  end

  describe "#perform" do
    context "when mascot user doesn't exist" do
      before do
        allow(User).to receive(:mascot_account).and_return(nil)
      end

      it "does nothing" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when no articles exist from the past day" do
      it "does nothing" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when there are fewer than 5 eligible articles" do
      let!(:article) do
        create(:article, :past,
               user: user,
               subforem_id: 1,
               title: "Single Article",
               body_markdown: "---\ntitle: Single Article\npublished: true\n---\n\nThis is the only article.",
               score: 30,
               past_published_at: 12.hours.ago)
      end

      it "does nothing" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when there are between 5-11 eligible articles" do
      let!(:articles) do
        5.times.map do |i|
          create(:article, :past,
                 user: create(:user),
                 subforem_id: 1,
                 title: "Article #{i}",
                 body_markdown: "---\ntitle: Article #{i}\npublished: true\n---\n\nThis is article #{i}.",
                 score: 20 + i,
                 past_published_at: 12.hours.ago)
        end
      end

      before do
        # Mock the AI service to return the first article as best
        allow_any_instance_of(Ai::ArticleQualityAssessor).to receive(:assess).and_return(
          { best: articles.first, worst: articles.last },
        )
      end

      it "only issues thumbs up, not thumbs down" do
        expect { described_class.new.perform }.to change(Reaction, :count).by(1)

        thumbs_up_reaction = Reaction.find_by(
          user: mascot_user,
          category: "thumbsup",
          status: "confirmed",
        )

        expect(thumbs_up_reaction).to be_present
        expect(thumbs_up_reaction.reactable).to eq(articles.first)

        # Should not have created a thumbs down
        expect(Reaction.exists?(
                 user: mascot_user,
                 category: "thumbsdown",
                 status: "confirmed",
               )).to be false
      end
    end

    context "when articles exist from the past day" do
      let!(:high_quality_article) do
        create(:article, :past,
               user: user,
               subforem_id: 1,
               title: "How to Build a Great Community: A Comprehensive Guide",
               body_markdown: "---\ntitle: How to Build a Great Community: A Comprehensive Guide\npublished: true\n---\n\nThis is a detailed tutorial with code examples.\n\n```ruby\ndef hello_world\n  puts 'Hello, World!'\nend\n```\n\nThis guide will help you understand the fundamentals.",
               score: 50,
               comments_count: 10,
               public_reactions_count: 25,
               reading_time: 8,
               past_published_at: 12.hours.ago)
      end

      let!(:low_quality_article) do
        create(:article, :past,
               user: spam_user,
               subforem_id: 1,
               title: "BUY NOW!!!",
               body_markdown: "---\ntitle: BUY NOW!!!\npublished: true\n---\n\nCLICK HERE TO GET AMAZING DEALS!!! LIMITED TIME OFFER!!! [Buy Now](https://spam-site.com) [Sign Up](https://another-spam.com) !!!",
               score: 5,
               comments_count: 1,
               public_reactions_count: 2,
               reading_time: 1,
               past_published_at: 6.hours.ago)
      end

      let!(:medium_quality_article) do
        create(:article, :past,
               user: create(:user),
               subforem_id: 1,
               title: "Some Article",
               body_markdown: "---\ntitle: Some Article\npublished: true\n---\n\nThis is a regular article with some content.",
               score: 20,
               comments_count: 5,
               public_reactions_count: 10,
               reading_time: 3,
               past_published_at: 18.hours.ago)
      end

      let!(:additional_article_1) do
        create(:article, :past,
               user: create(:user),
               subforem_id: 1,
               title: "Additional Article 1",
               body_markdown: "---\ntitle: Additional Article 1\npublished: true\n---\n\nThis is additional content.",
               score: 15,
               past_published_at: 10.hours.ago)
      end

      let!(:additional_article_2) do
        create(:article, :past,
               user: create(:user),
               subforem_id: 1,
               title: "Additional Article 2",
               body_markdown: "---\ntitle: Additional Article 2\npublished: true\n---\n\nThis is additional content.",
               score: 12,
               past_published_at: 8.hours.ago)
      end

      before do
        # Mock the AI service to return predictable results
        allow_any_instance_of(Ai::ArticleQualityAssessor).to receive(:assess).and_return(
          { best: high_quality_article, worst: low_quality_article },
        )
      end

      it "issues thumbs up to the best article" do
        expect { described_class.new.perform }.to change(Reaction, :count).by(1)

        thumbs_up_reaction = Reaction.find_by(
          user: mascot_user,
          category: "thumbsup",
          status: "confirmed",
        )

        expect(thumbs_up_reaction).to be_present
        expect(thumbs_up_reaction.reactable).to eq(high_quality_article)
      end

      it "issues thumbs down to the worst article when there are at least 12 articles" do
        # Create more articles to reach the 12+ threshold
        9.times do |i|
          create(:article, :past,
                 user: create(:user),
                 subforem_id: 1,
                 title: "Additional Article #{i}",
                 body_markdown: "---\ntitle: Additional Article #{i}\npublished: true\n---\n\nThis is additional content #{i}.",
                 score: 10 + i,
                 past_published_at: 12.hours.ago)
        end

        expect { described_class.new.perform }.to change(Reaction, :count).by(2)

        thumbs_down_reaction = Reaction.find_by(
          user: mascot_user,
          category: "thumbsdown",
          status: "confirmed",
        )

        expect(thumbs_down_reaction).to be_present
        expect(thumbs_down_reaction.reactable).to eq(low_quality_article)
      end

      it "removes conflicting reactions before creating new ones" do
        # Create more articles to ensure we have enough eligible articles even after filtering out existing reactions
        9.times do |i|
          create(:article, :past,
                 user: create(:user),
                 subforem_id: 1,
                 title: "Extra Article #{i}",
                 body_markdown: "---\ntitle: Extra Article #{i}\npublished: true\n---\n\nThis is extra content #{i}.",
                 score: 10 + i,
                 past_published_at: 12.hours.ago)
        end

        # Create an existing thumbs down on the high quality article
        create(:thumbsdown_reaction,
               user: mascot_user,
               reactable: high_quality_article,
               status: "confirmed")

        # Create an existing thumbs up on the low quality article
        create(:reaction,
               user: mascot_user,
               reactable: low_quality_article,
               category: "thumbsup",
               status: "confirmed")

        expect { described_class.new.perform }.not_to change(Reaction, :count) # 2 created, 2 destroyed

        # Verify the reactions were swapped
        expect(Reaction.exists?(
                 user: mascot_user,
                 reactable: high_quality_article,
                 category: "thumbsup",
                 status: "confirmed",
               )).to be true

        expect(Reaction.exists?(
                 user: mascot_user,
                 reactable: low_quality_article,
                 category: "thumbsdown",
                 status: "confirmed",
               )).to be true
      end

      it "logs the actions" do
        allow(Rails.logger).to receive(:info)

        described_class.new.perform

        expect(Rails.logger).to have_received(:info).with(
          "QualityReactionWorker: Subforem 1 - Issued thumbs up to article #{high_quality_article.id} " \
          "(only #{Article.published.where(subforem_id: 1).where('published_at > ?',
                                                                 1.day.ago).where('score >= 0').where.not(id: Reaction.where(user: mascot_user,
                                                                                                                             category: %w[
                                                                                                                               thumbsup thumbsdown
                                                                                                                             ]).select(:reactable_id)).count} eligible articles, skipping thumbs down)",
        )
      end
    end

    context "when articles are older than 1 day" do
      let!(:old_article) do
        create(:article, :past,
               user: user,
               subforem_id: 1,
               title: "Old Article",
               body_markdown: "---\ntitle: Old Article\npublished: true\n---\n\nThis is an old article.",
               score: 100,
               past_published_at: 2.days.ago)
      end

      it "does not consider articles older than 1 day" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when articles have negative scores" do
      let!(:negative_score_article) do
        create(:article, :past,
               user: user,
               subforem_id: 1,
               title: "Negative Score Article",
               body_markdown: "---\ntitle: Negative Score Article\npublished: true\n---\n\nThis article has a negative score.",
               score: -10,
               past_published_at: 12.hours.ago)
      end

      it "does not consider articles with negative scores" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when articles already have mascot reactions" do
      let!(:article_with_reaction) do
        create(:article, :past,
               user: user,
               subforem_id: 1,
               title: "Article with Reaction",
               body_markdown: "---\ntitle: Article with Reaction\npublished: true\n---\n\nThis article already has a mascot reaction.",
               score: 50,
               past_published_at: 12.hours.ago)
      end

      before do
        create(:reaction,
               user: mascot_user,
               reactable: article_with_reaction,
               category: "thumbsup",
               status: "confirmed")
      end

      it "does not consider articles that already have mascot reactions" do
        expect { described_class.new.perform }.not_to change(Reaction, :count)
      end
    end

    context "when there are fewer than 25 articles" do
      let!(:articles) do
        5.times.map do |i|
          create(:article, :past,
                 user: create(:user),
                 subforem_id: 1,
                 title: "Article #{i}",
                 body_markdown: "---\ntitle: Article #{i}\npublished: true\n---\n\nThis is article #{i}.",
                 score: 20 + i,
                 past_published_at: 12.hours.ago)
        end
      end

      before do
        # Mock the AI service to return the first article as best and last as worst
        allow_any_instance_of(Ai::ArticleQualityAssessor).to receive(:assess).and_return(
          { best: articles.first, worst: articles.last },
        )
      end

      it "still processes the available articles" do
        expect { described_class.new.perform }.to change(Reaction, :count).by(1)

        # Should issue thumbs up to the best article (only 5 articles, so no thumbs down)
        expect(Reaction.exists?(
                 user: mascot_user,
                 reactable: articles.first,
                 category: "thumbsup",
                 status: "confirmed",
               )).to be true
      end
    end
  end
end
