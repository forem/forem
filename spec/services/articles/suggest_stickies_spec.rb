require "rails_helper"

RSpec.describe Articles::SuggestStickies, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, cached_tag_list: "ruby") }

  # Create articles with SUGGESTION_TAGS that meet the score/comment_score thresholds.
  # We create first, then update published_at via update_column to bypass validation.
  let!(:career_articles) do
    articles = create_list(:article, 3, published: true, cached_tag_list: "career",
                                        score: 50, comment_score: 20)
    articles.each { |a| a.update_columns(published_at: 1.day.ago) }
    articles
  end
  let!(:discuss_articles) do
    articles = create_list(:article, 2, published: true, cached_tag_list: "discuss",
                                        score: 50, comment_score: 20)
    articles.each { |a| a.update_columns(published_at: 1.day.ago) }
    articles
  end

  describe ".call" do
    it "returns articles with limited attributes needed by _sticky_nav" do
      result = described_class.call(article)
      expect(result).not_to be_empty

      sticky = result.first
      # Columns explicitly selected for _sticky_nav (suggest stickies section):
      expect { sticky.id }.not_to raise_error
      expect { sticky.path }.not_to raise_error
      expect { sticky.title }.not_to raise_error
      expect { sticky.cached_tag_list }.not_to raise_error
      expect { sticky.cached_user }.not_to raise_error
      expect { sticky.organization_id }.not_to raise_error
      expect { sticky.user_id }.not_to raise_error
    end

    it "allows accessing cached_user avatar data (used in view)" do
      result = described_class.call(article)
      expect(result).not_to be_empty

      sticky = result.first
      # _sticky_nav calls article.cached_user.profile_image_url_for and cached_user.name
      cached_user = sticky.cached_user
      expect(cached_user).not_to be_nil
      expect { cached_user.name }.not_to raise_error
    end

    it "allows decorating for cached_tag_list_array (used in view)" do
      result = described_class.call(article)
      expect(result).not_to be_empty

      sticky = result.first
      # _sticky_nav calls article.decorate.cached_tag_list_array
      expect { sticky.decorate.cached_tag_list_array }.not_to raise_error
    end

    it "does not include the current article" do
      result = described_class.call(article)
      expect(result.map(&:id)).not_to include(article.id)
    end

    it "does not include articles by the same author" do
      result = described_class.call(article)
      expect(result.map(&:user_id)).not_to include(article.user_id)
    end

    it "does not include archived articles" do
      career_articles.first.update_column(:archived, true)
      discuss_articles.first.update_column(:archived, true)
      result = described_class.call(article, sample_size: 10)
      expect(result.map(&:id)).not_to include(career_articles.first.id)
      expect(result.map(&:id)).not_to include(discuss_articles.first.id)
    end

    it "does not load unnecessary columns (proves optimization)" do
      result = described_class.call(article)
      next if result.empty?

      sticky = result.first
      expect { sticky.body_markdown }.to raise_error(ActiveModel::MissingAttributeError)
      expect { sticky.processed_html }.to raise_error(ActiveModel::MissingAttributeError)
    end

    it "returns an array" do
      result = described_class.call(article)
      expect(result).to be_a(Array)
    end

    it "handles article with nil cached_tag_list without querying empty tag_articles" do
      article.update_column(:cached_tag_list, nil)
      allow(Article).to receive(:cached_tagged_with_any).and_call_original
      expect(described_class.call(article.reload)).to be_a(Array)
      expect(Article).not_to have_received(:cached_tagged_with_any).with([])
    end

    it "skips the tag_articles query when cached_tag_list only contains discuss" do
      article.update_column(:cached_tag_list, "discuss")
      allow(Article).to receive(:cached_tagged_with_any).and_call_original
      expect(described_class.call(article.reload)).to be_a(Array)
      expect(Article).not_to have_received(:cached_tagged_with_any).with([])
    end

    it "deduplicates articles that match both tag_articles and more_articles" do
      article.update_column(:cached_tag_list, "career")
      result = described_class.call(article.reload, sample_size: 10)
      expect(result.map(&:id)).to eq(result.map(&:id).uniq)
    end

    it "excludes articles below the non-production score and comment_score thresholds" do
      low_scored = create(:article, published: true, tags: "ruby, career",
                                    score: -1, comment_score: -2)
      low_scored.update_columns(published_at: 1.day.ago)

      result = described_class.call(article, sample_size: 10)
      expect(result.map(&:id)).not_to include(low_scored.id)
    end

    context "when in production environment" do
      let(:ruby_article) { create(:article, user: user, published: true, tags: "ruby") }

      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "includes tag_articles with score > 25 or comment_score > 15 and excludes those below both" do
        high_score_tag_article = create(:article, published: true, tags: "ruby",
                                                  score: 26, comment_score: 0)
        high_comment_score_tag_article = create(:article, published: true, tags: "ruby",
                                                          score: 5, comment_score: 16)
        below_threshold_tag_article = create(:article, published: true, tags: "ruby",
                                                       score: 25, comment_score: 15,
                                                       public_reactions_count: 50, comments_count: 20)
        [high_score_tag_article, high_comment_score_tag_article, below_threshold_tag_article].each do |a|
          a.update_columns(published_at: 1.day.ago)
        end

        result_ids = described_class.call(ruby_article, sample_size: 20).map(&:id)
        expect(result_ids).to include(high_score_tag_article.id, high_comment_score_tag_article.id)
        expect(result_ids).not_to include(below_threshold_tag_article.id)
      end

      it "requires comment_score > 15 for more_articles" do
        score_only_suggestion_article = create(:article, published: true, tags: "productivity",
                                                         score: 40, comment_score: 15, comments_count: 20)
        qualifying_suggestion_article = create(:article, published: true, tags: "productivity",
                                                         score: 10, comment_score: 16)
        [score_only_suggestion_article, qualifying_suggestion_article].each do |a|
          a.update_columns(published_at: 1.day.ago)
        end

        result_ids = described_class.call(ruby_article, sample_size: 20).map(&:id)
        expect(result_ids).to include(qualifying_suggestion_article.id)
        expect(result_ids).not_to include(score_only_suggestion_article.id)
      end
    end
  end
end
