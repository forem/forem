class HtmlVariant < ApplicationRecord
  self.ignored_columns = %w[success_rate].freeze

  resourcify

  GROUP_NAMES = %w[article_show_below_article_cta badge_landing_page campaign].freeze

  belongs_to :user, optional: true

  before_validation :strip_whitespace

  validates :group, inclusion: { in: GROUP_NAMES }
  validates :html, presence: true
  validates :name, uniqueness: true

  validate  :no_edits

  before_save :prefix_all_images

  scope :relevant, -> { where(approved: true, published: true) }

  private

  def no_edits
    return if group == "campaign"

    published_and_approved = (approved && (html_changed? || name_changed? || group_changed?)) && persisted?
    errors.add(:base, I18n.t("models.html_variant.no_edits")) if published_and_approved
  end

  def prefix_all_images
    # Optimize image if not from giphy or githubusercontent.com
    doc = Nokogiri::HTML.fragment(html)
    doc.css("img").each do |img|
      src = img.attr("src")
      next unless src
      next if allowed_image_host?(src)

      img["src"] = if Giphy::Image.valid_url?(src)
                     src.gsub("https://media.", "https://i.")
                   else
                     Images::Optimizer.call(src, width: 420).gsub(",", "%2C")
                   end
    end
    self.html = doc.to_html
  end

  def allowed_image_host?(src)
    src.start_with?("https://res.cloudinary.com/") || src.start_with?(Images::Optimizer.get_imgproxy_endpoint)
  end

  def strip_whitespace
    name.strip!
  end
end
