# This "model" is not backed by the database. Its main purpose is giving one of
# our domain concepts an actual representation in code.
class Campaign
  include Singleton

  # Ruby's singleton exposes the instance via a method of the same name, but we
  # prefer a friendlier name.
  def self.current
    instance
  end

  METHODS = %w[
    hero_html_variant_name
    featured_tags
    sidebar_enabled?
    sidebar_image
    url
    articles_require_approval?
  ].freeze

  # Define delegate methods for SiteConfig
  METHODS.each { |m| define_method(m) { SiteConfig.public_send("campaign_#{m}") } }

  def show_in_sidebar?
    sidebar_enabled? && sidebar_image.present?
  end
end
