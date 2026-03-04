class OrgPostsTag < LiquidTagBase
  PARTIAL = "liquids/org_posts".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  def initialize(_tag_name, input, _parse_context)
    super
    @org_slug = input.strip
    @organization = Organization.find_by(slug: @org_slug)
    raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_slug") unless @organization
  end

  def render(_context)
    articles = @organization.articles.published
      .includes(:distinct_reaction_categories, :subforem)
      .limited_column_select
      .order(published_at: :desc)
      .limit(8)

    ApplicationController.render(
      partial: PARTIAL,
      locals: { articles: ArticleDecorator.decorate_collection(articles) },
      assigns: { organization_article_index: true },
    )
  end
end

Liquid::Template.register_tag("org_posts", OrgPostsTag)
