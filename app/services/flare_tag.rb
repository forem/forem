class FlareTag
  FLARE_TAG_IDS_HASH = Tag.where(name: Constants::Tags::FLARE_TAG_NAMES).pluck(:name, :id).to_h.freeze
  TAG_ATTRIBUTES = %i[name bg_color_hex text_color_hex].freeze

  # Resolves the flare tag of every article with a single tags query instead of
  # one per article. Returns { article_id => tag }, omitting articles without one.
  def self.tags_by_article_id(articles, except_tag = nil)
    flare_map = FLARE_TAG_IDS_HASH
    return {} if flare_map.empty?

    tag_ids = nil
    allowed_names = flare_tag_names_for(flare_map)
    except_str = except_tag.is_a?(String) || except_tag.nil? ? except_tag : except_tag.to_s

    articles.each do |article|
      resolved_id = resolve_article_tag_id(article, except_str, flare_map, allowed_names)
      next unless resolved_id

      tag_ids ||= {}
      tag_ids[article.id] = resolved_id
    end
    return {} unless tag_ids

    tags = tags_by_id
    tag_ids.each_with_object({}) do |(article_id, resolved_id), result|
      tag = tags[resolved_id]
      result[article_id] = tag if tag
    end
  end

  # Every flare tag, loaded once per request (or Sidekiq job) so story lists that call
  # FlareTag.new(story).tag per story share one tags query instead of one per story.
  # Keyed on the flare tag ids so a different id set never reads a stale entry.
  def self.tags_by_id
    RequestStore.fetch([:flare_tags_by_id, FLARE_TAG_IDS_HASH.values]) do
      Tag.select(:id, *TAG_ATTRIBUTES).where(id: FLARE_TAG_IDS_HASH.values).index_by(&:id)
    end
  end

  def self.flare_tag_names_for(flare_map)
    if flare_map.equal?(@cached_flare_map)
      @cached_flare_tag_names
    else
      @cached_flare_map = flare_map
      @cached_flare_tag_names = flare_map.keys.freeze
    end
  end
  private_class_method :flare_tag_names_for

  def self.resolve_tag_id_for(article, except_tag = nil)
    flare_map = FLARE_TAG_IDS_HASH
    return if flare_map.empty?

    except_str = except_tag.is_a?(String) || except_tag.nil? ? except_tag : except_tag.to_s
    resolve_article_tag_id(article, except_str, flare_map, flare_tag_names_for(flare_map))
  end

  def self.resolve_article_tag_id(article, except_tag, flare_map, allowed_names)
    return legacy_tag_id_for(article, except_tag, flare_map) unless article.respond_to?(:cached_tag_list)

    raw_tags = article.cached_tag_list
    return if raw_tags.blank?
    return legacy_tag_id_for(article, except_tag, flare_map) unless raw_tags.is_a?(String)

    matched_name = ForemNative.match_first_flare_tag(raw_tags, allowed_names)
    return if matched_name == false
    return legacy_tag_id_for(article, except_tag, flare_map) if matched_name.nil?

    flare_map[matched_name] if matched_name != except_tag
  end
  private_class_method :resolve_article_tag_id

  def self.legacy_tag_id_for(article, except_tag, flare_map)
    target = article.respond_to?(:cached_tag_list_array) ? article : article.decorate
    tag_name, tag_id = flare_map.slice(*target.cached_tag_list_array).first
    tag_id if tag_name && tag_name != except_tag
  end
  private_class_method :legacy_tag_id_for

  def initialize(article, except_tag = nil)
    @article = if article.respond_to?(:cached_tag_list) || article.respond_to?(:cached_tag_list_array)
                 article
               else
                 article.decorate
               end
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
    self.class.resolve_tag_id_for(article, except_tag)
  end

  private

  attr_reader :article, :except_tag
end
