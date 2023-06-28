# This "model" is not backed by the database. Its main purpose is giving one of
# our domain concepts an actual representation in code.
class Campaign
  include Singleton

  METHODS = %w[
    articles_expiry_time
    articles_require_approval?
    call_to_action
    display_name
    featured_tags
    hero_html_variant_name
    sidebar_enabled?
    sidebar_image
    url
  ].freeze
  # Ruby's singleton exposes the instance via a method of the same name, but we
  # prefer a friendlier name.
  def self.current
    instance
  end

  delegate(*METHODS, to: Settings::Campaign)

  def show_in_sidebar?
    sidebar_enabled? && sidebar_image.present?
  end

  # @return [Integer] The total number of articles in the campaign.
  delegate :count, to: :articles_scope

  # Get the "plucked" attribute information for the campaign's
  # articles.
  #
  # @param limit [Integer] The limit of the number of articles to
  #        fetch and render.
  # @param attributes [Array<Symbol>] The named attributes to pluck
  #        from the Article result set.
  #
  # @return [Array<Array>] The inner array is the plucked attribute
  #         values for the selected articles.  Which means be mindful
  #         of the order you pass for attributes.
  #
  # @note The order of attributes and behavior of this method is from
  #       past implementations.  A refactor to consider would be to
  #       create a data structure.
  #
  # @see `./app/views/articles/_widget_list_item.html.erb` for the
  #      importance of maintaining position of these parameters.
  def plucked_article_attributes(limit: 5, attributes: %i[path title comments_count created_at])
    articles_scope.limit(limit).pluck(*attributes)
  end

  private

  # @note [@jeremyf] My inclination was to extract a scoping method
  #       for this.  However, I've since consolidated the logic into a
  #       single location, so the scope is less necessary.
  def articles_scope
    articles_scope = Article
      .tagged_with(featured_tags, any: true)
      .where("published_at > ? AND score > ?", articles_expiry_time.weeks.ago, 0)
      .order(hotness_score: :desc)
    articles_scope = articles_scope.approved if articles_require_approval?

    articles_scope
  end
end
