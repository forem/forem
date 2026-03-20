class FeedTag < LiquidTagBase
  PARTIAL = "liquids/feed".freeze

  VALID_OPTIONS = %w[org tag tags limit sort min_reactions min_comments since].freeze
  VALID_SORTS = %w[recent reactions comments score].freeze
  MAX_LIMIT = 30
  DEFAULT_LIMIT = 8
  OPTION_REGEXP = /\A(\w+)=(\S+)\z/

  def initialize(_tag_name, input, _parse_context)
    super
    parse_options(input.strip.split)
    validate_source
  end

  def render(_context)
    articles = build_query
    articles = apply_filters(articles)
    articles = apply_sort(articles).limit(@limit)

    ApplicationController.render(
      partial: PARTIAL,
      locals: { articles: ArticleDecorator.decorate_collection(articles) },
    )
  end

  private

  def parse_options(tokens)
    @limit = DEFAULT_LIMIT
    @sort = "recent"
    @org_slug = nil
    @tag_names = []
    @min_reactions = nil
    @min_comments = nil
    @since_date = nil

    tokens.each do |token|
      match = token.match(OPTION_REGEXP)
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_option", option: token) unless match

      key, value = match[1], match[2]
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_option", option: key) unless VALID_OPTIONS.include?(key)

      send(:"parse_#{key}", value)
    end
  end

  def validate_source
    raise StandardError, I18n.t("liquid_tags.feed_tag.missing_source") if @org_slug.nil? && @tag_names.empty?
  end

  def parse_org(value)
    @org_slug = value
    @organization = Organization.find_by(slug: @org_slug)
    raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_org", slug: @org_slug) unless @organization
  end

  def parse_tag(value)
    @tag_names = [value]
  end

  def parse_tags(value)
    names = value.split(",").map(&:strip).reject(&:empty?)
    raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_tags") if names.empty?

    @tag_names = names
  end

  def parse_limit(value)
    @limit = Integer(value, exception: false)
    unless @limit && @limit >= 1 && @limit <= MAX_LIMIT
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_limit")
    end
  end

  def parse_sort(value)
    unless VALID_SORTS.include?(value)
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_sort")
    end

    @sort = value
  end

  def parse_min_reactions(value)
    @min_reactions = Integer(value, exception: false)
    unless @min_reactions && @min_reactions >= 0
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_option", option: "min_reactions=#{value}")
    end
  end

  def parse_min_comments(value)
    @min_comments = Integer(value, exception: false)
    unless @min_comments && @min_comments >= 0
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_option", option: "min_comments=#{value}")
    end
  end

  def parse_since(value)
    if value.match?(/\A\d+d\z/)
      @since_date = value.to_i.days.ago
    elsif value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
      @since_date = Date.parse(value)
    else
      raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_since")
    end
  rescue Date::Error
    raise StandardError, I18n.t("liquid_tags.feed_tag.invalid_since")
  end

  def build_query
    articles = if @organization
                 @organization.articles.published
               else
                 Article.published
               end

    articles = articles.cached_tagged_with_any(@tag_names) if @tag_names.any?

    articles
      .includes(:distinct_reaction_categories, :subforem)
      .limited_column_select
  end

  def apply_filters(articles)
    articles = articles.where("public_reactions_count >= ?", @min_reactions) if @min_reactions
    articles = articles.where("comments_count >= ?", @min_comments) if @min_comments
    articles = articles.where("published_at >= ?", @since_date) if @since_date
    articles
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

Liquid::Template.register_tag("feed", FeedTag)
