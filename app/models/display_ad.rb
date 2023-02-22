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
  validate :validate_tag
  before_save :process_markdown
  after_save :generate_display_ad_name

  scope :approved_and_published, -> { where(approved: true, published: true) }

  scope :search_ads, lambda { |term|
                       where "name ILIKE :search OR processed_html ILIKE :search OR placement_area ILIKE :search",
                             search: "%#{term}%"
                     }

  def self.for_display(area, user_signed_in, article_tags = [])
    DisplayAds::FilteredAdsQuery.call(
      display_ads: self,
      area: area,
      user_signed_in: user_signed_in,
      article_tags: article_tags,
    )
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
    super(options.merge(except: %i[tags tag_list])).merge("tag_list" => cached_tag_list)
  end
  # rubocop:enable Style/OptionHash

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
