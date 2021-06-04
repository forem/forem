require "rails_helper"

RSpec.describe PinnedArticle, type: :model do
  let(:article) { create(:article) }

  describe ".exists?" do
    it "returns false if there is no pinned article" do
      Settings::General.feed_pinned_article_id = nil

      expect(described_class.exists?).to be(false)
    end

    it "returns false if the pinned article has been unpublished" do
      Settings::General.feed_pinned_article_id = article.id

      article.update_columns(published: false)

      expect(described_class.exists?).to be(false)
    end

    it "returns false if the pinned article has been deleted" do
      Settings::General.feed_pinned_article_id = article.id

      article.destroy

      expect(described_class.exists?).to be(false)
    end

    it "returns true if there is a pinned article" do
      Settings::General.feed_pinned_article_id = article.id

      expect(described_class.exists?).to be(true)
    end
  end

  describe ".id" do
    it "returns nil if there is no pinned article" do
      Settings::General.feed_pinned_article_id = nil

      expect(described_class.id).to be_nil
    end

    it "returns nil if the pinned article has been unpublished" do
      Settings::General.feed_pinned_article_id = article.id

      article.update_columns(published: false)

      expect(described_class.id).to be_nil
    end

    it "returns nil if the pinned article has been deleted" do
      Settings::General.feed_pinned_article_id = article.id

      article.destroy

      expect(described_class.id).to be_nil
    end

    it "returns the id of the pinned article" do
      Settings::General.feed_pinned_article_id = article.id

      expect(described_class.id).to eq(article.id)
    end
  end

  describe ".get" do
    it "returns nil if there is no pinned article" do
      Settings::General.feed_pinned_article_id = nil

      expect(described_class.get).to be_nil
    end

    it "returns nil if the pinned article has been unpublished" do
      Settings::General.feed_pinned_article_id = article.id

      article.update_columns(published: false)

      expect(described_class.get).to be_nil
    end

    it "returns nil if the pinned article has been deleted" do
      Settings::General.feed_pinned_article_id = article.id

      article.destroy

      expect(described_class.get).to be_nil
    end

    it "returns the pinned article" do
      Settings::General.feed_pinned_article_id = article.id

      expect(described_class.get.id).to eq(article.id)
    end
  end

  describe ".set" do
    it "sets the pinned article" do
      expect(Settings::General.feed_pinned_article_id).to be_nil

      described_class.set(article)

      expect(Settings::General.feed_pinned_article_id).to eq(article.id)
    end

    it "overwrites the current pinned article" do
      Settings::General.feed_pinned_article_id = article.id

      another_article = create(:article)
      described_class.set(another_article)

      expect(Settings::General.feed_pinned_article_id).to eq(another_article.id)
    end
  end

  describe ".remove" do
    it "works even if there is no pinned article" do
      Settings::General.feed_pinned_article_id = nil

      described_class.remove

      expect(Settings::General.feed_pinned_article_id).to be_nil
    end

    it "removes the currently pinned article" do
      Settings::General.feed_pinned_article_id = article.id

      described_class.remove

      expect(Settings::General.feed_pinned_article_id).to be_nil
    end
  end
end
