class FlareTag
  FLARE_TAG_IDS_HASH = Tag.where(name: Constants::Tags::FLARE_TAG_NAMES).pluck(:name, :id).to_h.freeze
  TAG_ATTRIBUTES = %i[name bg_color_hex text_color_hex].freeze
  DEFAULT_FLARE_TAG_SET = Constants::Tags::FLARE_TAG_NAMES.to_set.freeze

  # Resolves the flare tag of every article with a single tags query instead of
  # one per article. Returns { article_id => tag }, omitting articles without one.
  def self.tags_by_article_id(articles, except_tag = nil)
    tag_ids = {}
    articles.each do |article|
      tid = tag_id_for(article, except_tag)
      tag_ids[article.id] = tid if tid
    end
    return {} if tag_ids.empty?

    tags = tags_by_id
    result = {}
    tag_ids.each do |article_id, tid|
      tag = tags[tid]
      result[article_id] = tag if tag
    end
    result
  end

  def self.tag_id_for(article, except_tag = nil)
    return if FLARE_TAG_IDS_HASH.empty?

    raw_tags = article.cached_tag_list
    return if raw_tags.blank?

    matched = ForemNative.match_first_flare_tag(raw_tags, allowed_flare_tag_names)
    return if matched == false
    return FLARE_TAG_IDS_HASH[matched] if matched && matched != except_tag
    return if matched

    legacy_tag_id_for(article, except_tag)
  end

  def self.allowed_flare_tag_names
    hash = FLARE_TAG_IDS_HASH
    return @allowed_flare_tag_names if @cached_flare_hash_id == hash.object_id

    keys = hash.keys
    @cached_flare_hash_id = hash.object_id
    @allowed_flare_tag_names =
      if keys.size == DEFAULT_FLARE_TAG_SET.size && keys.all? { |k| DEFAULT_FLARE_TAG_SET.include?(k) }
        nil
      else
        keys.freeze
      end
  end
  private_class_method :allowed_flare_tag_names

  def self.legacy_tag_id_for(article, except_tag = nil)
    tags = (article.cached_tag_list || "").split(", ")
    tag_name, tag_id = FLARE_TAG_IDS_HASH.slice(*tags).first
    tag_id if tag_name && tag_name != except_tag
  end
  private_class_method :legacy_tag_id_for

  # Every flare tag, loaded once per request (or Sidekiq job) so story lists that call
  # FlareTag.new(story).tag per story share one tags query instead of one per story.
  # Keyed on the flare tag ids so a different id set never reads a stale entry.
  def self.tags_by_id
    RequestStore.fetch([:flare_tags_by_id, FLARE_TAG_IDS_HASH.values]) do
      Tag.select(:id, *TAG_ATTRIBUTES).where(id: FLARE_TAG_IDS_HASH.values).index_by(&:id)
    end
  end

  def initialize(article, except_tag = nil)
    @article = article
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
    self.class.tag_id_for(article, except_tag)
  end

  private

  attr_reader :article, :except_tag
end
