class DisplayAd < ApplicationRecord
  include Taggable
  acts_as_taggable_on :tags
  resourcify

  ALLOWED_PLACEMENT_AREAS = %w[sidebar_left sidebar_left_2 sidebar_right post_comments].freeze
  ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE = ["Sidebar Left (First Position)",
                                            "Sidebar Left (Second Position)",
                                            "Sidebar Right",
                                            "Below the comment section"].freeze

  MAX_TAG_LIST_SIZE = 10
  POST_WIDTH = 775
  SIDEBAR_WIDTH = 350

  enum display_to: { all: 0, logged_in: 1, logged_out: 2 }, _prefix: true

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
    relation = approved_and_published.where(placement_area: area).order(success_rate: :desc)

    if article_tags.any?
      display_ads_with_no_tags = relation.where(cached_tag_list: "")
      display_ads_with_targeted_article_tags = relation.cached_tagged_with_any(article_tags)

      relation = display_ads_with_no_tags.or(display_ads_with_targeted_article_tags)
    end

    if article_tags.blank?
      relation = relation.where(cached_tag_list: "")
    end

    relation = if user_signed_in
                 relation.where(display_to: %w[all logged_in])
               else
                 relation.where(display_to: %w[all logged_out])
               end

    relation.order(success_rate: :desc)

    if rand(8) == 1
      relation.sample
    else
      relation.limit(rand(1..15)).sample
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
