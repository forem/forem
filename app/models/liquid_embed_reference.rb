class LiquidEmbedReference < ApplicationRecord
  FEED_TAG_NAMES = %w[org_posts feed].freeze
  FEED_TARGETS_CACHE_KEY = "liquid_embed_references:feed_targets:v1".freeze
  FEED_TARGETS_CACHE_TTL = 15.minutes
  INLINE_SVG_RANDOM_ID_REGEX = /\b(aria-labelledby|id)="a[0-9a-z]{25,35}"/

  belongs_to :record, polymorphic: true
  belongs_to :referenced, polymorphic: true, optional: true

  validates :tag_name, presence: true
  validates :url, presence: true

  scope :published, -> { where(published: true).where("published_at <= ? OR published_at IS NULL", Time.current) }
  scope :unpublished, -> { where(published: false).or(where("published_at > ?", Time.current)) }
  scope :popular, -> { order(score: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_tag, ->(tag_name) { where(tag_name: tag_name) }

  def self.record_published?(record)
    if defined?(Billboard) && record.is_a?(Billboard)
      record.approved? && record.published? && (record.expires_at.nil? || record.expires_at > Time.current)
    elsif record.respond_to?(:published)
      record.published == true
    else
      true
    end
  end

  def self.semantically_equal_html?(html_a, html_b)
    return true if html_a == html_b
    return false if html_a.nil? || html_b.nil?

    html_a.gsub(INLINE_SVG_RANDOM_ID_REGEX, '\1="svg-id"') ==
      html_b.gsub(INLINE_SVG_RANDOM_ID_REGEX, '\1="svg-id"')
  end

  def self.bust_feed_targets_cache!
    Rails.cache.delete(FEED_TARGETS_CACHE_KEY)
  end

  def self.cached_feed_targets
    Rails.cache.fetch(FEED_TARGETS_CACHE_KEY, expires_in: FEED_TARGETS_CACHE_TTL) do
      build_feed_targets
    end
  end

  def self.build_feed_targets
    rows = where(tag_name: FEED_TAG_NAMES)
      .where.not(referenced_id: nil)
      .pluck(:referenced_type, :referenced_id, :record_type, :published)

    org_ids = []
    billboard_org_ids = []
    tag_billboard_by_id = {}

    rows.each do |ref_type, ref_id, rec_type, is_pub|
      is_live_billboard = rec_type == "Billboard" && is_pub
      case ref_type
      when "Organization"
        org_ids << ref_id
        billboard_org_ids << ref_id if is_live_billboard
      when "Tag"
        tag_billboard_by_id[ref_id] = tag_billboard_by_id.fetch(ref_id, false) || is_live_billboard
      end
    end

    {
      org_ids: org_ids.uniq,
      billboard_org_ids: billboard_org_ids.uniq,
      tags: resolve_tracked_tag_names(tag_billboard_by_id)
    }
  end
  private_class_method :build_feed_targets

  def self.resolve_tracked_tag_names(tag_billboard_by_id)
    return {} if tag_billboard_by_id.empty?

    Tag.where(id: tag_billboard_by_id.keys).pluck(:id, :name).to_h do |id, name|
      [name.to_s.downcase, tag_billboard_by_id[id]]
    end
  end
  private_class_method :resolve_tracked_tag_names

  def self.dependency_status_for_article(article_id, organization_ids: nil, tag_names: nil)
    return { any: false, billboard: false } if article_id.blank?

    direct_rows = where(referenced_type: "Article", referenced_id: article_id).pluck(:record_type, :published)
    return { any: true, billboard: true } if direct_rows.any? { |rec_type, is_pub| rec_type == "Billboard" && is_pub }

    feed_status = feed_dependency_status(article_id, organization_ids: organization_ids, tag_names: tag_names)
    {
      any: direct_rows.any? || feed_status[:any],
      billboard: feed_status[:billboard]
    }
  end

  def self.feed_dependency_status(article_id, organization_ids:, tag_names:)
    targets = cached_feed_targets
    return { any: false, billboard: false } if targets[:org_ids].empty? && targets[:tags].empty?

    org_ids, parsed_tags = resolve_article_feed_context(
      article_id,
      organization_ids: organization_ids,
      tag_names: tag_names,
    )
    return { any: true, billboard: true } if org_ids.intersect?(targets[:billboard_org_ids])

    matching_tags = parsed_tags.select { |tag_name| targets[:tags].key?(tag_name) }
    {
      any: org_ids.intersect?(targets[:org_ids]) || matching_tags.any?,
      billboard: matching_tags.any? { |tag_name| targets[:tags][tag_name] }
    }
  end
  private_class_method :feed_dependency_status

  def self.resolve_article_feed_context(article_id, organization_ids:, tag_names:)
    if organization_ids.nil? && tag_names.nil?
      org_id, raw_tag_list = Article.where(id: article_id).pick(:organization_id, :cached_tag_list)
      [org_id ? [org_id] : [], parse_tag_list(raw_tag_list)]
    else
      org_ids = Array(organization_ids).compact.map(&:to_i).uniq
      tags = Array(tag_names).flat_map { |entry| parse_tag_list(entry) }.uniq
      [org_ids, tags]
    end
  end
  private_class_method :resolve_article_feed_context

  def self.parse_tag_list(raw)
    return [] if raw.blank?

    raw.to_s.split(",").map { |t| t.strip.downcase }.compact_blank.uniq
  end
end
