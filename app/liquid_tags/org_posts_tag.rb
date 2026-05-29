class OrgPostsTag < LiquidTagBase
  PARTIAL = "liquids/org_posts".freeze
  VALID_CONTEXTS = %w[Organization].freeze

  VALID_OPTIONS = %w[limit sort min_reactions min_comments since].freeze
  VALID_SORTS = %w[recent reactions comments score].freeze
  MAX_LIMIT = 30
  DEFAULT_LIMIT = 8
  OPTION_REGEXP = /\A(\w+)=(\S+)\z/

  def initialize(_tag_name, input, _parse_context)
    super
    tokens = input.strip.split
    @org_slug = tokens.first
    @organization = Organization.find_by(slug: @org_slug)
    raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_slug") unless @organization

    parse_options(tokens.drop(1))
  end

  def render(_context)
    articles = @organization.articles.published
      .includes(:distinct_reaction_categories, :subforem)
      .limited_column_select

    articles = articles.where("public_reactions_count >= ?", @min_reactions) if @min_reactions
    articles = articles.where("comments_count >= ?", @min_comments) if @min_comments
    articles = articles.where("published_at >= ?", @since_date) if @since_date

    articles = apply_sort(articles)
      .limit(@limit)

    ApplicationController.render(
      partial: PARTIAL,
      locals: { articles: ArticleDecorator.decorate_collection(articles) },
      assigns: { organization_article_index: false },
    )
  end

  private

  def parse_options(option_tokens)
    @limit = DEFAULT_LIMIT
    @sort = "recent"
    @min_reactions = nil
    @min_comments = nil
    @since_date = nil

    option_tokens.each do |token|
      match = token.match(OPTION_REGEXP)
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_option", option: token) unless match

      key, value = match[1], match[2]
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_option", option: key) unless VALID_OPTIONS.include?(key)

      send(:"parse_#{key}", value)
    end
  end

  def parse_limit(value)
    @limit = Integer(value, exception: false)
    unless @limit && @limit >= 1 && @limit <= MAX_LIMIT
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_limit")
    end
  end

  def parse_sort(value)
    unless VALID_SORTS.include?(value)
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_sort")
    end

    @sort = value
  end

  def parse_min_reactions(value)
    @min_reactions = Integer(value, exception: false)
    unless @min_reactions && @min_reactions >= 0
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_option", option: "min_reactions=#{value}")
    end
  end

  def parse_min_comments(value)
    @min_comments = Integer(value, exception: false)
    unless @min_comments && @min_comments >= 0
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_option", option: "min_comments=#{value}")
    end
  end

  def parse_since(value)
    if value.match?(/\A\d+d\z/)
      days = value.to_i
      @since_date = days.days.ago
    elsif value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      @since_date = Date.parse(value)
    else
      raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_since")
    end
  rescue Date::Error
    raise StandardError, I18n.t("liquid_tags.org_posts_tag.invalid_since")
  end

  def apply_sort(articles)
    case @sort
    when "reactions"
      articles.order(public_reactions_count: :desc)
    when "comments"
      articles.order(comments_count: :desc)
    when "score"
      articles.order(score: :desc)
    else
      articles.order(published_at: :desc)
    end
  end
end

Liquid::Template.register_tag("org_posts", OrgPostsTag)
