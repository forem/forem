class Billboard < ApplicationRecord
  include Taggable
  acts_as_taggable_on :tags
  resourcify
  belongs_to :creator, class_name: "User", optional: true
  belongs_to :audience_segment, optional: true
  belongs_to :page, optional: true

  ALLOWED_PLACEMENT_AREAS = %w[sidebar_left
                               sidebar_left_2
                               sidebar_right
                               sidebar_right_second
                               sidebar_right_third
                               feed_first
                               feed_second
                               feed_third
                               home_hero
                               footer
                               page_fixed_bottom
                               post_fixed_bottom
                               post_body_bottom
                               post_sidebar
                               post_comments
                               post_comments_mid
                               digest_first
                               digest_second].freeze
  ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE = ["Sidebar Left (First Position)",
                                            "Sidebar Left (Second Position)",
                                            "Sidebar Right (Home first position)",
                                            "Sidebar Right (Home second position)",
                                            "Sidebar Right (Home third position)",
                                            "Home Feed First",
                                            "Home Feed Second",
                                            "Home Feed Third",
                                            "Home Hero",
                                            "Footer",
                                            "Fixed Bottom (Page)",
                                            "Fixed Bottom (Individual Post)",
                                            "Below the post body",
                                            "Sidebar Right (Individual Post)",
                                            "Below the comment section",
                                            "Midway through the comment section",
                                            "Digest Email First",
                                            "Digest Email Second"].freeze

  HOME_FEED_PLACEMENTS = %w[feed_first feed_second feed_third].freeze

  COLOR_HEX_REGEXP = /\A#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\z/

  MAX_TAG_LIST_SIZE = 25
  POST_WIDTH = 775
  SIDEBAR_WIDTH = 350
  LOW_IMPRESSION_COUNT = 1_000
  RANDOM_RANGE_MAX_FALLBACK = 5
  NEW_AND_PRIORITY_RANGE_MAX_FALLBACK = 35
  NEW_ONLY_RANGE_MAX_FALLBACK = 40

  attribute :target_geolocations, :geolocation_array
  enum display_to: { all: 0, logged_in: 1, logged_out: 2 }, _prefix: true
  enum type_of: { in_house: 0, community: 1, external: 2 }
  enum render_mode: { forem_markdown: 0, raw: 1 }
  enum template: { authorship_box: 0, plain: 1 }
  enum :special_behavior, { nothing: 0, delayed: 1 }
  enum :browser_context, { all_browsers: 0, desktop: 1, mobile_web: 2, mobile_in_app: 3 }

  belongs_to :organization, optional: true
  has_many :billboard_events, foreign_key: :display_ad_id, inverse_of: :billboard, dependent: :destroy

  validates :placement_area, presence: true,
                             inclusion: { in: ALLOWED_PLACEMENT_AREAS }
  validates :body_markdown, presence: true
  validates :organization, presence: true, if: :community?
  validates :weight, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }
  validates :audience_segment_type,
            inclusion: { in: AudienceSegment.type_ofs },
            allow_blank: true
  validates :color, format: COLOR_HEX_REGEXP, allow_blank: true
  validate :valid_audience_segment_match,
           :validate_in_house_hero_ads,
           :valid_manual_audience_segment,
           :validate_tag,
           :validate_geolocations

  before_save :process_markdown
  after_save :generate_billboard_name
  after_save :refresh_audience_segment, if: :should_refresh_audience_segment?
  after_save :update_links_with_bb_param

  scope :approved_and_published, -> { where(approved: true, published: true) }

  scope :search_ads, lambda { |term|
                       where "name ILIKE :search OR processed_html ILIKE :search OR placement_area ILIKE :search",
                             search: "%#{term}%"
                     }

  scope :seldom_seen, ->(area) { where("impressions_count < ?", low_impression_count(area)).or(where(priority: true)) }
  scope :new_only, ->(area) { where("impressions_count < ?", low_impression_count(area)) }

  self.table_name = "display_ads"

  def self.for_display(area:, user_signed_in:, user_id: nil, article: nil, user_tags: nil,
                       location: nil, cookies_allowed: false, page_id: nil, user_agent: nil,
                       role_names: nil)
    permit_adjacent = article ? article.permit_adjacent_sponsors? : true

    billboards_for_display = Billboards::FilteredAdsQuery.call(
      billboards: self,
      area: area,
      user_signed_in: user_signed_in,
      article_id: article&.id,
      article_tags: article&.cached_tag_list_array || [],
      organization_id: article&.organization_id,
      permit_adjacent_sponsors: permit_adjacent,
      user_id: user_id,
      page_id: page_id,
      user_tags: user_tags,
      location: location,
      cookies_allowed: cookies_allowed,
      user_agent: user_agent,
      role_names: role_names,
    )

    case rand(99) # output integer from 0-99
    when (0..random_range_max(area)) # smallest range, 5%
      # We are always showing more of the good stuff — but we are also always testing the system to give any a chance to
      # rise to the top. 5 out of every 100 times we show an ad (5%), it is totally random. This gives "not yet
      # evaluated" stuff a chance to get some engagement and start showing up more. If it doesn't get engagement, it
      # stays in this area.
      billboards_for_display.sample
    when (random_range_max(area)..new_and_priority_range_max(area)) # medium range, 30%
      # Here we sample from only billboards with fewer than 1000 impressions (with a fallback
      # if there are none of those, causing an extra query, but that shouldn't happen very often).
      relation = billboards_for_display.seldom_seen(area)
      weighted_random_selection(relation, article&.id) || billboards_for_display.sample
    when (new_and_priority_range_max(area)..new_only_range_max(area)) # 5% by default
      # Here we sample from only billboards with fewer than 1000 impressions (with a fallback
      billboards_for_display.new_only(area).sample || billboards_for_display.limit(rand(1..15)).sample
    else # large range, 65%

      # Ads that get engagement have a higher "success rate", and among this category, we sample from the top 15 that
      # meet that criteria. Within those 15 top "success rates" likely to be clicked, there is a weighting towards the
      # top ranked outcome as well, and a steady decline over the next 15 — that's because it's not "Here are the top 15
      # pick one randomly", it is actually "Let's cut off the query at a random limit between 1 and 15 and sample from
      # that". So basically the "limit" logic will result in 15 sets, and then we sample randomly from there. The
      # "first ranked" ad will show up in all 15 sets, where as 15 will only show in 1 of the 15.
      billboards_for_display.limit(rand(1..15)).sample
    end
  end

  def self.weighted_random_selection(relation, target_article_id = nil)
    base_query = relation.to_sql
    random_val = rand.to_f
    if FeatureFlag.enabled?(:article_id_adjusted_weight)
      condition = target_article_id.blank? ? "FALSE" : "#{target_article_id} = ANY(preferred_article_ids)"
      query = <<-SQL
        WITH base AS (#{base_query}),
        weighted AS (
          SELECT *,
            CASE
              WHEN #{condition} THEN weight * 10
              ELSE weight
            END AS adjusted_weight,
          SUM(CASE
                WHEN #{condition} THEN weight * 10
                ELSE weight
              END) OVER () AS total_weight,
          SUM(CASE
                WHEN #{condition} THEN weight * 10
                ELSE weight
              END) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_weight
          FROM base
        )
        SELECT *, running_weight, ? * total_weight AS random_value FROM weighted
        WHERE running_weight >= ? * total_weight
        ORDER BY running_weight ASC
        LIMIT 1
      SQL
    else
      query = <<-SQL
        WITH base AS (#{base_query}),
        weighted AS (
          SELECT *, weight,
          SUM(weight) OVER () AS total_weight,
          SUM(weight) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_weight
          FROM base
        )
        SELECT *, running_weight, ? * total_weight AS random_value FROM weighted
        WHERE running_weight >= ? * total_weight
        ORDER BY running_weight ASC
        LIMIT 1
      SQL
    end
    relation.find_by_sql([query, random_val, random_val]).first
  end

  # Temporary ENV configs, to eventually be replaced by permanent configurations
  # once we determine what the appropriate long-term config approach is.

  def self.low_impression_count(placement_area)
    ApplicationConfig["LOW_IMPRESSION_COUNT_FOR_#{placement_area.upcase}"] ||
      ApplicationConfig["LOW_IMPRESSION_COUNT"] ||
      LOW_IMPRESSION_COUNT
  end

  def self.random_range_max(placement_area)
    selected_number = ApplicationConfig["SELDOM_SEEN_MIN_FOR_#{placement_area.upcase}"] ||
      ApplicationConfig["SELDOM_SEEN_MIN"] ||
      RANDOM_RANGE_MAX_FALLBACK
    selected_number.to_i
  end

  def self.new_and_priority_range_max(placement_area)
    selected_number = ApplicationConfig["SELDOM_SEEN_MAX_FOR_#{placement_area.upcase}"] ||
      ApplicationConfig["SELDOM_SEEN_MAX"] ||
      NEW_AND_PRIORITY_RANGE_MAX_FALLBACK
    selected_number.to_i
  end

  def self.new_only_range_max(placement_area)
    selected_number = ApplicationConfig["NEW_ONLY_MAX_FOR_#{placement_area.upcase}"] ||
      ApplicationConfig["NEW_ONLY_MAX"] ||
      NEW_ONLY_RANGE_MAX_FALLBACK
    selected_number.to_i
  end

  def processed_html_final
    # This is a final non-database-driven step to adjust processed html
    # It is sort of a hack to avoid having to reprocess all articles
    # It is currently only for this one cloudflare domain change
    # It is duplicated across article, bullboard and comment where it is most needed
    # In the future this could be made more customizable. For now it's just this one thing.
    return processed_html if ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"].blank? || ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"].blank?

    processed_html.gsub(ApplicationConfig["PRIOR_CLOUDFLARE_IMAGES_DOMAIN"], ApplicationConfig["CLOUDFLARE_IMAGES_DOMAIN"])
  end

  def type_of_display
    type_of.gsub("external", "partner")
  end

  def human_readable_placement_area
    ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE[ALLOWED_PLACEMENT_AREAS.find_index(placement_area)]
  end

  def validate_tag
    # check there are not too many tags
    return errors.add(:tag_list, I18n.t("models.article.too_many_tags")) if tag_list.size > MAX_TAG_LIST_SIZE

    validate_tag_name(tag_list)
  end

  def validate_geolocations
    target_geolocations.each do |geo|
      unless geo.valid?(:targeting)
        errors.add(:target_geolocations, I18n.t("models.billboard.invalid_location", location: geo.to_iso3166))
      end
    end
  end

  def validate_in_house_hero_ads
    return unless placement_area == "home_hero" && type_of != "in_house"

    errors.add(:type_of, "must be in_house if billboard is a Home Hero")
  end

  def audience_segment_type
    @audience_segment_type ||= audience_segment&.type_of
  end

  def audience_segment_type=(type)
    errors.delete(:audience_segment_type)
    @audience_segment_type = type
  end

  # This needs to correspond with Rails built-in method signature
  # rubocop:disable Style/OptionHash
  def as_json(options = {})
    overrides = {
      "audience_segment_type" => audience_segment_type,
      "tag_list" => cached_tag_list,
      "exclude_article_ids" => exclude_article_ids.join(","),
      "target_geolocations" => target_geolocations.map(&:to_iso3166)
    }
    super(options.merge(except: %i[tags tag_list target_geolocations])).merge(overrides)
  end
  # rubocop:enable Style/OptionHash

  # exclude_article_ids and preferred_article_ids are integer arrays, web inputs are comma-separated strings
  # ActiveRecord normalizes these in a bad way, so we are intervening
  def exclude_article_ids=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    adjusted_input = adjusted_input&.filter_map { |value| value.presence&.to_i }
    write_attribute :exclude_article_ids, (adjusted_input || [])
  end

  def preferred_article_ids=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    adjusted_input = adjusted_input&.filter_map { |value| value.presence&.to_i }
    write_attribute :preferred_article_ids, (adjusted_input || [])
  end

  def exclude_role_names=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    write_attribute :exclude_role_names, (adjusted_input || [])
  end

  def target_role_names=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    write_attribute :target_role_names, (adjusted_input || [])
  end

  def include_subforem_ids=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    adjusted_input = adjusted_input&.filter_map { |value| value.presence&.to_i }
    write_attribute :include_subforem_ids, (adjusted_input || [])
  end

  def style_string
    return "" if color.blank?

    if placement_area.include?("fixed_")
      "border-top: calc(9px + 0.5vw) solid #{color}"
    else
      "border: 5px solid #{color}"
    end
  end

  def update_links_with_bb_param
    # Parse the processed_html with Nokogiri
    full_html = "<html><head></head><body>#{processed_html}</body></html>"
    doc = Nokogiri::HTML(full_html)
    # Iterate over all the <a> tags
    doc.css("a").each do |link|
      href = link["href"]
      next unless href.present? && href.start_with?("http", "/")

      uri = URI.parse(href)
      existing_params = URI.decode_www_form(uri.query || "")
      # Check if 'bb' parameter exists and update it or append if not exists
      bb_param_index = existing_params.find_index { |param| param[0] == "bb" }
      if bb_param_index
        existing_params[bb_param_index][1] = id.to_s # Update existing 'bb' parameter
      else
        existing_params << ["bb", id.to_s] # Append new 'bb' parameter
      end
      uri.query = URI.encode_www_form(existing_params)
      link["href"] = uri.to_s
    end

    # Extract and save only the inner HTML of the body
    modified_html = doc.at("body").inner_html

    modified_html.gsub!(/href="([^"]*)&amp;([^"]*)"/, 'href="\1&\2"')

    # Early return if the new HTML is the same as the old one
    return if modified_html == processed_html

    # Update the processed_html column with the new HTML
    update_column(:processed_html, modified_html)
  end

  private

  def generate_billboard_name
    return unless name.nil?

    self.name = "Billboard #{id}"
    save!
  end

  def process_markdown
    return unless body_markdown_changed?

    if render_mode == "forem_markdown"
      extracted_process_markdown
    else # raw
      self.processed_html = Html::Parser.new(body_markdown)
        .prefix_all_images(width: 880, quality: 100, synchronous_detail_detection: true).html
    end
  end

  def score
    0 # Just to allow this to repond to .score for abuse reports
  end

  def extracted_process_markdown
    renderer = ContentRenderer.new(body_markdown || "", source: self)
    self.processed_html = renderer.process(prefix_images_options: { width: prefix_width,
                                                                    quality: 100,
                                                                    synchronous_detail_detection: true }).processed_html
    self.processed_html = processed_html.delete("\n")
  end

  def prefix_width
    placement_area.include?("sidebar") ? SIDEBAR_WIDTH : POST_WIDTH
  end

  def refresh_audience_segment
    AudienceSegmentRefreshWorker.perform_async(audience_segment_id)
  end

  def should_refresh_audience_segment?
    change_relevant_to_audience = saved_change_to_approved? ||
      saved_change_to_published? ||
      saved_change_to_audience_segment_id?

    change_relevant_to_audience &&
      audience_segment &&
      audience_segment.updated_at < 1.day.ago
  end

  def valid_audience_segment_match
    return if audience_segment.blank? || audience_segment_type.blank?

    errors.add(:audience_segment_type) if audience_segment.type_of.to_s != audience_segment_type.to_s
  end

  def valid_manual_audience_segment
    return if audience_segment_type != "manual"

    errors.add(:audience_segment_type) if audience_segment.blank?
  end
end
