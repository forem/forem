class FlareTag
  FLARE_TAG_IDS_HASH = Tag.where(name: Constants::Tags::FLARE_TAG_NAMES).pluck(:name, :id).to_h.freeze
  TAG_ATTRIBUTES = %i[name bg_color_hex text_color_hex].freeze

  # Resolves the flare tag of every article with a single tags query instead of
  # one per article. Returns { article_id => tag }, omitting articles without one.
  def self.tags_by_article_id(articles, except_tag = nil)
    tag_ids = articles.to_h { |article| [article.id, new(article, except_tag).tag_id] }.compact
    return {} if tag_ids.empty?

    tags = tags_by_id
    tag_ids.transform_values { |tag_id| tags[tag_id] }.compact
  end

  # Every flare tag, loaded once per request (or Sidekiq job) so story lists that call
  # FlareTag.new(story).tag per story share one tags query instead of one per story.
  # Keyed on the flare tag ids so a different id set never reads a stale entry.
  def self.tags_by_id
    RequestStore.fetch([:flare_tags_by_id, FLARE_TAG_IDS_HASH.values]) do
      Tag.select(:id, *TAG_ATTRIBUTES).where(id: FLARE_TAG_IDS_HASH.values).index_by(&:id)
    end
  end

  def initialize(article, except_tag = nil)
    @article = article.decorate
    @except_tag = except_tag
  end

  def tag
    @tag ||= if tag_id
               self.class.tags_by_id[tag_id]
             end
  end

  def tag_hash
    tag&.slice(*TAG_ATTRIBUTES)
  end

  def tag_id
    tag_name, tag_id = FLARE_TAG_IDS_HASH.slice(*article.cached_tag_list_array).first
    tag_id if tag_name && tag_name != except_tag
  end

  private

  attr_reader :article, :except_tag
end
