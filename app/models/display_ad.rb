class DisplayAd < ApplicationRecord
  resourcify

  ALLOWED_PLACEMENT_AREAS = %w[sidebar_left sidebar_left_2 sidebar_right].freeze
  ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE = ["Sidebar Left (First Position)",
                                            "Sidebar Left (Second Position)",
                                            "Sidebar Right"].freeze

  belongs_to :organization, optional: true
  has_many :display_ad_events, dependent: :destroy

  validates :placement_area, presence: true,
                             inclusion: { in: ALLOWED_PLACEMENT_AREAS }
  validates :body_markdown, presence: true
  before_save :process_markdown

  scope :approved_and_published, -> { where(approved: true, published: true) }

  ALLOWED_TAGS = %w[
    a abbr add b blockquote br center cite code col colgroup dd del dl dt em figcaption
    h1 h2 h3 h4 h5 h6 hr img kbd li mark ol p pre q rp rt ruby small source span strong sub sup table
    tbody td tfoot th thead time tr u ul video
  ].freeze
  ALLOWED_ATTRIBUTES = %w[href src alt height width].freeze

  def self.for_display(area)
    relation = approved_and_published.where(placement_area: area).order(success_rate: :desc)

    if rand(8) == 1
      relation.sample
    else
      relation.limit(rand(1..15)).sample
    end
  end

  def human_readable_placement_area
    ALLOWED_PLACEMENT_AREAS_HUMAN_READABLE[ALLOWED_PLACEMENT_AREAS.find_index(placement_area)]
  end

  private

  def process_markdown
    renderer = Redcarpet::Render::HTMLRouge.new(hard_wrap: true, filter_html: false)
    markdown = Redcarpet::Markdown.new(renderer)
    initial_html = markdown.render(body_markdown)
    stripped_html = ActionController::Base.helpers.sanitize initial_html,
                                                            tags: ALLOWED_TAGS,
                                                            attributes: ALLOWED_ATTRIBUTES
    html = stripped_html.delete("\n")
    self.processed_html = Html::Parser.new(html).prefix_all_images(350, synchronous_detail_detection: true).html
  end
end
