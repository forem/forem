require "rails_helper"

RSpec.describe Articles::SuggestStickies, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, cached_tag_list: "ruby") }

  # Create articles with SUGGESTION_TAGS that meet the reaction/comment thresholds.
  # We create first, then update published_at via update_column to bypass validation.
  let!(:career_articles) do
    articles = create_list(:article, 3, published: true, cached_tag_list: "career",
                           public_reactions_count: 50, comments_count: 10)
    articles.each { |a| a.update_columns(published_at: 1.day.ago) }
    articles
  end
  let!(:discuss_articles) do
    articles = create_list(:article, 2, published: true, cached_tag_list: "discuss",
                           public_reactions_count: 50, comments_count: 10)
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

    it "handles article with nil cached_tag_list" do
      article.update_column(:cached_tag_list, nil)
      result = described_class.call(article.reload)
      expect(result).to be_a(Array)
    end
  end
end
