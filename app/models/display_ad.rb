class DisplayAd < ApplicationRecord
  include Taggable
  acts_as_taggable_on :tags
  resourcify
  belongs_to :creator, class_name: "User", optional: true

  ALLOWED_PLACEMENT_AREAS = %w[sidebar_left sidebar_left_2 sidebar_right post_sidebar post_comments].freeze
  ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE = ["Sidebar Left (First Position)",
                                            "Sidebar Left (Second Position)",
                                            "Sidebar Right (Home)",
                                            "Sidebar Right (Individual Post)",
                                            "Below the comment section"].freeze

  MAX_TAG_LIST_SIZE = 10
  POST_WIDTH = 775
  SIDEBAR_WIDTH = 350

  enum display_to: { all: 0, logged_in: 1, logged_out: 2 }, _prefix: true
  enum type_of: { in_house: 0, community: 1, external: 2 }

  belongs_to :organization, optional: true
  has_many :display_ad_events, dependent: :destroy

  validates :placement_area, presence: true,
                             inclusion: { in: ALLOWED_PLACEMENT_AREAS }
  validates :body_markdown, presence: true
  validates :organization, presence: true, if: :community?
  validate :validate_tag

  before_save :process_markdown
  after_save :generate_display_ad_name

  scope :approved_and_published, -> { where(approved: true, published: true) }

  scope :search_ads, lambda { |term|
                       where "name ILIKE :search OR processed_html ILIKE :search OR placement_area ILIKE :search",
                             search: "%#{term}%"
                     }

  def self.for_display(area:, user_signed_in:, organization_id: nil, article_id: nil,
                       article_tags: [], permit_adjacent_sponsors: true)
    ads_for_display = DisplayAds::FilteredAdsQuery.call(
      display_ads: self,
      area: area,
      organization_id: organization_id,
      user_signed_in: user_signed_in,
      article_id: article_id,
      article_tags: article_tags,
      permit_adjacent_sponsors: permit_adjacent_sponsors,
    )

    # Business Logic Context:
    # We are always showing more of the good stuff — but we are also always testing the system to give any a chance to
    # rise to the top. 1 out of every 8 times we show an ad (12.5%), it is totally random. This gives "not yet
    # evaluated" stuff a chance to get some engagement and start showing up more. If it doesn't get engagement, it
    # stays in this area.

    # Ads that get engagement have a higher "success rate", and among this category, we sample from the top 15 that
    # meet that criteria. Within those 15 top "success rates" likely to be clicked, there is a weighting towards the
    # top ranked outcome as well, and a steady decline over the next 15 — that's because it's not "Here are the top 15
    # pick one randomly", it is actually "Let's cut off the query at a random limit between 1 and 15 and sample from
    # that". So basically the "limit" logic will result in 15 sets, and then we sample randomly from there. The
    # "first ranked" ad will show up in all 15 sets, where as 15 will only show in 1 of the 15.
    if rand(8) == 1
      ads_for_display.sample
    else
      ads_for_display.limit(rand(1..15)).sample
    end
  end

  def human_readable_placement_area
    ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE[ALLOWED_PLACEMENT_AREAS.find_index(placement_area)]
  end

  def validate_tag
    # check there are not too many tags
    return errors.add(:tag_list, I18n.t("models.article.too_many_tags")) if tag_list.size > MAX_TAG_LIST_SIZE

    validate_tag_name(tag_list)
  end

  # This needs to correspond with Rails built-in method signature
  # rubocop:disable Style/OptionHash
  def as_json(options = {})
    overrides = {
      "tag_list" => cached_tag_list,
      "exclude_article_ids" => exclude_article_ids.join(",")
    }
    super(options.merge(except: %i[tags tag_list])).merge(overrides)
  end
  # rubocop:enable Style/OptionHash

  # exclude_article_ids is an integer array, web inputs are comma-separated strings
  # ActiveRecord normalizes these in a bad way, so we are intervening
  def exclude_article_ids=(input)
    adjusted_input = input.is_a?(String) ? input.split(",") : input
    adjusted_input = adjusted_input&.filter_map { |value| value.presence&.to_i }
    write_attribute :exclude_article_ids, (adjusted_input || [])
  end

  private

  def generate_display_ad_name
    return unless name.nil?

    self.name = "Display Ad #{id}"
    save!
  end

  def process_markdown
    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer, Constants::Redcarpet::CONFIG)
    initial_html = markdown.render(body_markdown)
    stripped_html = ActionController::Base.helpers.sanitize initial_html,
                                                            tags: MarkdownProcessor::AllowedTags::DISPLAY_AD,
                                                            attributes: MarkdownProcessor::AllowedAttributes::DISPLAY_AD
    html = stripped_html.delete("\n")
    self.processed_html = Html::Parser.new(html)
      .prefix_all_images(prefix_width, synchronous_detail_detection: true).html
  end

  def prefix_width
    placement_area.to_s == "post_comments" ? POST_WIDTH : SIDEBAR_WIDTH
  end
end
