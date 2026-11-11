class LiquidEmbedReference < ApplicationRecord
  FEED_TAG_NAMES = %w[org_posts feed].freeze
  FEED_TARGETS_CACHE_KEY = "liquid_embed_references:feed_targets:v2".freeze
  FEED_TARGETS_CACHE_TTL = 15.minutes
  INLINE_SVG_RANDOM_ID_REGEX = /\b(aria-labelledby|id)="a[0-9a-z]{25,35}"/

  BILLBOARD_ENGAGEMENT_INTERVAL = 15.seconds
  ENGAGEMENT_BACKOFF_BASE = 60
  PAGE_MAX_ENGAGEMENT_BACKOFF = 5.minutes
  COOLDOWN_GATE_THRESHOLD = 1.hour
  MAX_ENGAGEMENT_BACKOFF = 72.hours
  AGE_BACKOFF_MILESTONES = [
    30.minutes,
    1.hour,
    3.hours,
    6.hours,
    12.hours,
    1.day,
    3.days,
    7.days,
    14.days,
    30.days,
    90.days,
    180.days,
    365.days,
  ].freeze

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

  # Doubles the engagement refresh interval across age milestones (60s -> 2m -> 4m -> ... -> 72h)
  # so older content backs off exponentially without flooding Sidekiq.
  def self.engagement_backoff_interval(age_seconds)
    age = [age_seconds.to_f, 0.0].max
    step = AGE_BACKOFF_MILESTONES.count { |milestone| age >= milestone.to_f }
    [(ENGAGEMENT_BACKOFF_BASE * (2**step)).seconds, MAX_ENGAGEMENT_BACKOFF].min
  end

  def self.record_engagement_backoff(record, now: Time.current)
    return BILLBOARD_ENGAGEMENT_INTERVAL if defined?(Billboard) && record.is_a?(Billboard)

    timestamp = record_published_at(record) || now
    interval = engagement_backoff_interval(now - timestamp)
    return [interval, PAGE_MAX_ENGAGEMENT_BACKOFF].min if defined?(Page) && record.is_a?(Page)

    interval
  end

  def self.record_published_at(record)
    pub_at = record.published_at if record.respond_to?(:published_at)
    pub_at || (record.created_at if record.respond_to?(:created_at)) ||
      (record.updated_at if record.respond_to?(:updated_at))
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
      .pluck(:referenced_type, :referenced_id, :record_type, :published, :published_at, :created_at)

    orgs = {}
    tag_entries_by_id = {}

    rows.each do |ref_type, ref_id, rec_type, is_pub, pub_at, created_at|
      raw_time = pub_at || created_at
      entry_time = raw_time ? raw_time.to_i : 0
      case ref_type
      when "Organization"
        accumulate_feed_target!(orgs, ref_id, rec_type, is_pub, entry_time)
      when "Tag"
        accumulate_feed_target!(tag_entries_by_id, ref_id, rec_type, is_pub, entry_time)
      end
    end

    {
      orgs: orgs,
      tags: resolve_tracked_tag_targets(tag_entries_by_id)
    }
  end
  private_class_method :build_feed_targets

  def self.accumulate_feed_target!(map, key, rec_type, is_pub, entry_time)
    slot = (map[key] ||= { any: true, published: false, billboard: false, page: false, newest_at: 0 })
    return unless is_pub

    slot[:published] = true
    slot[:billboard] = true if rec_type == "Billboard"
    slot[:page] = true if rec_type == "Page"
    slot[:newest_at] = entry_time if entry_time > slot[:newest_at]
  end
  private_class_method :accumulate_feed_target!

  def self.resolve_tracked_tag_targets(tag_entries_by_id)
    return {} if tag_entries_by_id.empty?

    Tag.where(id: tag_entries_by_id.keys).pluck(:id, :name).to_h do |id, name|
      [name.to_s.downcase, tag_entries_by_id[id]]
    end
  end
  private_class_method :resolve_tracked_tag_targets

  def self.dependency_status_for_article(article_id, organization_ids: nil, tag_names: nil, published_only: false)
    if article_id.blank?
      return { any: false, billboard: false, refresh_interval: MAX_ENGAGEMENT_BACKOFF }
    end

    now = Time.current
    direct_status = direct_dependency_status(article_id, published_only: published_only, now: now)
    if direct_status[:billboard]
      return { any: true, billboard: true, refresh_interval: BILLBOARD_ENGAGEMENT_INTERVAL }
    end

    feed_status = feed_dependency_status(
      article_id,
      organization_ids: organization_ids,
      tag_names: tag_names,
      published_only: published_only,
      now: now,
    )
    any_match = direct_status[:any] || feed_status[:any]
    is_billboard = feed_status[:billboard]
    interval = if is_billboard
                 BILLBOARD_ENGAGEMENT_INTERVAL
               else
                 [direct_status[:refresh_interval], feed_status[:refresh_interval]].min
               end

    { any: any_match, billboard: is_billboard, refresh_interval: interval }
  end

  def self.direct_dependency_status(article_id, published_only:, now:)
    scope = where(referenced_type: "Article", referenced_id: article_id)
    scope = scope.where(published: true) if published_only
    rows = scope.pluck(:record_type, :published, :published_at, :created_at)
    return { any: false, billboard: false, refresh_interval: MAX_ENGAGEMENT_BACKOFF } if rows.empty?

    has_live_billboard = false
    min_interval = MAX_ENGAGEMENT_BACKOFF

    rows.each do |rec_type, is_pub, pub_at, created_at|
      if rec_type == "Billboard" && is_pub
        has_live_billboard = true
        break
      end
      next if published_only && !is_pub

      age = now.to_f - (pub_at || created_at || now).to_f
      row_interval = engagement_backoff_interval(age)
      row_interval = [row_interval, PAGE_MAX_ENGAGEMENT_BACKOFF].min if rec_type == "Page"
      min_interval = row_interval if row_interval < min_interval
    end

    { any: true, billboard: has_live_billboard, refresh_interval: min_interval }
  end
  private_class_method :direct_dependency_status

  def self.feed_dependency_status(article_id, organization_ids:, tag_names:, published_only:, now:)
    targets = cached_feed_targets
    if targets[:orgs].empty? && targets[:tags].empty?
      return { any: false, billboard: false, refresh_interval: MAX_ENGAGEMENT_BACKOFF }
    end

    org_ids, parsed_tags, source_age = resolve_article_feed_context(
      article_id,
      organization_ids: organization_ids,
      tag_names: tag_names,
      now: now,
    )

    matched_slots = collect_matching_feed_slots(targets, org_ids, parsed_tags, published_only: published_only)
    return { any: false, billboard: false, refresh_interval: MAX_ENGAGEMENT_BACKOFF } if matched_slots.empty?

    if matched_slots.any? { |slot| slot[:billboard] }
      return { any: true, billboard: true, refresh_interval: BILLBOARD_ENGAGEMENT_INTERVAL }
    end

    min_interval = matched_slots.map { |slot| feed_slot_interval(slot, source_age, now) }.min
    { any: true, billboard: false, refresh_interval: min_interval }
  end
  private_class_method :feed_dependency_status

  def self.collect_matching_feed_slots(targets, org_ids, parsed_tags, published_only:)
    slots = org_ids.filter_map { |org_id| targets[:orgs][org_id] }
    parsed_tags.each do |tag_name|
      slot = targets[:tags][tag_name]
      slots << slot if slot
    end
    published_only ? slots.select { |slot| slot[:published] } : slots
  end
  private_class_method :collect_matching_feed_slots

  def self.feed_slot_interval(slot, source_age, now)
    if slot[:page]
      [engagement_backoff_interval(source_age), PAGE_MAX_ENGAGEMENT_BACKOFF].min
    else
      holder_age = slot[:newest_at].positive? ? (now.to_f - slot[:newest_at]) : 0.0
      engagement_backoff_interval([holder_age, source_age].max)
    end
  end
  private_class_method :feed_slot_interval

  def self.resolve_article_feed_context(article_id, organization_ids:, tag_names:, now:)
    if organization_ids.nil? && tag_names.nil?
      org_id, raw_tag_list, pub_at, created_at = Article
        .where(id: article_id)
        .pick(:organization_id, :cached_tag_list, :published_at, :created_at)
      source_age = now.to_f - (pub_at || created_at || now).to_f
      [org_id ? [org_id] : [], parse_tag_list(raw_tag_list), [source_age, 0.0].max]
    else
      org_ids = Array(organization_ids).compact.map(&:to_i).uniq
      tags = Array(tag_names).flat_map { |entry| parse_tag_list(entry) }.uniq
      [org_ids, tags, 0.0]
    end
  end
  private_class_method :resolve_article_feed_context

  def self.parse_tag_list(raw)
    return [] if raw.blank?

    raw.to_s.split(",").map { |t| t.strip.downcase }.compact_blank.uniq
  end
end
