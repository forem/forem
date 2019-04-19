class HtmlVariant < ApplicationRecord
  include CloudinaryHelper

  validates :html, presence: true
  validates :name, uniqueness: true
  validates :group, inclusion: { in: %w[article_show_sidebar_cta article_show_below_article_cta badge_landing_page] }
  validates :success_rate, presence: true
  validate  :no_edits
  belongs_to :user, optional: true
  has_many :html_variant_trials
  has_many :html_variant_successes
  before_save :prefix_all_images

  def calculate_success_rate!
    self.success_rate = html_variant_successes.size.to_f / (html_variant_trials.size * 10.0) # x10 because we only capture every 10th
    save!
  end

  def self.find_for_test(tags = [], group = "article_show_sidebar_cta")
    tags_array = tags + ["", nil]
    if rand(10) == 1 # 10% return completely random
      find_random_for_test(tags_array, group)
    else # 90% chance return one in top 10
      find_top_for_test(tags_array, group)
    end
  end

  def self.find_top_for_test(tags_array, group)
    where(group: group, approved: true, published: true, target_tag: tags_array).order("success_rate DESC").limit(rand(1..15)).sample
  end

  def self.find_random_for_test(tags_array, group)
    where(group: group, approved: true, published: true, target_tag: tags_array).order(Arel.sql("RANDOM()")).first
  end

  private

  def no_edits
    errors.add(:base, "cannot change once published and approved") if (approved && (html_changed? || name_changed? || group_changed?)) && persisted?
  end

  def prefix_all_images
    # wrap with Cloudinary or allow if from giphy or githubusercontent.com
    doc = Nokogiri::HTML.fragment(html)
    doc.css("img").each do |img|
      src = img.attr("src")
      next unless src
      next if allowed_image_host?(src)

      img["src"] = if giphy_img?(src)
                     src.gsub("https://media.", "https://i.")
                   else
                     img_of_size(src, 420)
                   end
    end
    self.html = doc.to_html
  end

  def giphy_img?(source)
    uri = URI.parse(source)
    return false if uri.scheme != "https"
    return false if uri.userinfo || uri.fragment || uri.query
    return false if uri.host != "media.giphy.com" && uri.host != "i.giphy.com"
    return false if uri.port != 443 # I think it has to be this if its https?

    uri.path.ends_with?(".gif")
  end

  def allowed_image_host?(src)
    src.start_with?("https://res.cloudinary.com/")
  end

  def img_of_size(source, width = 420)
    quality = if source && (source.include? ".gif")
                66
              else
                "auto"
              end
    cl_image_path(source,
                  type: "fetch",
                  width: width,
                  crop: "limit",
                  quality: quality,
                  flags: "progressive",
                  fetch_format: "auto",
                  sign_url: true).gsub(",", "%2C")
  end
end
