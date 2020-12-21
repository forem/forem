class HtmlVariant < ApplicationRecord
  resourcify

  GROUP_NAMES = %w[article_show_below_article_cta badge_landing_page campaign].freeze

  belongs_to :user, optional: true

  has_many :html_variant_successes, dependent: :destroy
  has_many :html_variant_trials, dependent: :destroy

  validates :group, inclusion: { in: GROUP_NAMES }
  validates :html, presence: true
  validates :name, uniqueness: true
  validates :success_rate, presence: true

  validate  :no_edits

  before_save :prefix_all_images

  scope :relevant, -> { where(approved: true, published: true) }

  def calculate_success_rate!
    # x10 because we only capture every 10th
    self.success_rate = html_variant_successes.size.to_f / (html_variant_trials.size * 10.0)
    save!
  end

  class << self
    def find_for_test(tags = [], group = "article_show_below_article_cta")
      tags_array = tags + ["", nil]
      if rand(10) == 1 # 10% return completely random
        find_random_for_test(tags_array, group)
      else # 90% chance return one of the top posts
        find_top_for_test(tags_array, group)
      end
    end

    private

    def find_top_for_test(tags_array, group)
      where(group: group, approved: true, published: true, target_tag: tags_array)
        .order(success_rate: :desc).limit(rand(1..20)).sample
    end

    def find_random_for_test(tags_array, group)
      where(group: group, approved: true, published: true, target_tag: tags_array)
        .order(Arel.sql("RANDOM()")).first
    end
  end

  private

  def no_edits
    return if group == "campaign"

    published_and_approved = (approved && (html_changed? || name_changed? || group_changed?)) && persisted?
    errors.add(:base, "cannot change once published and approved") if published_and_approved
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
end
