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
    articles_require_approval?
    call_to_action
    featured_tags
    hero_html_variant_name
    sidebar_enabled?
    sidebar_image
    url
  ].freeze

  delegate(*METHODS, to: Settings::Campaign)

  def show_in_sidebar?
    sidebar_enabled? && sidebar_image.present?
  end
end
