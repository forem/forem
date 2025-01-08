class ArticleApiIndexService
  DEFAULT_PER_PAGE = 30

  def initialize(params)
    @page = params[:page].to_i
    @tag = params[:tag]
    @tags = params[:tags]
    @tags_exclude = params[:tags_exclude]
    @username = params[:username]
    @state = params[:state]
    @sort = params[:sort]
    @top = params[:top]
    @collection_id = params[:collection_id]
    @per_page = [(params[:per_page] || DEFAULT_PER_PAGE).to_i, per_page_max].min
  end

  def get
    if tag.present?
      tag_articles
    elsif tags.present? || tags_exclude.present?
      tagged_articles
    elsif username.present?
      username_articles
    elsif state.present?
      state_articles(state)
    elsif top.present?
      top_articles
    elsif collection_id.present?
      collection_articles(collection_id)
    elsif sort.present?
      sorted_articles(sort)
    else
      base_articles
    end
  end

  private

  attr_reader :tag, :tags, :tags_exclude, :username, :page, :state, :sort, :top, :collection_id, :per_page

  def per_page_max
    (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
  end

  def username_articles
    num = if @state == "all"
            per_page_max
          else
            DEFAULT_PER_PAGE
          end

    if (user = User.includes(:profile).find_by(username: username))
      user.articles.published.from_subforem
        .includes(:organization)
        .order(published_at: :desc)
        .page(page)
        .per(per_page || num)
    elsif (organization = Organization.find_by(slug: username))
      organization.articles.published.from_subforem
        .includes(user: :profile)
        .order(published_at: :desc)
        .page(page)
        .per(per_page || num)
    else
      Article.none
    end
  end

  def tag_articles
    articles = published_articles_with_users_and_organizations.cached_tagged_with(tag)

    articles = if Tag.find_by(name: tag)&.requires_approval
                 articles.approved.order(published_at: :desc)
               elsif top.present?
                 articles.where("published_at > ?", top.to_i.days.ago)
                   .order(public_reactions_count: :desc)
               else
                 articles.order(hotness_score: :desc)
               end

    articles.page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def tagged_articles
    articles = published_articles_with_users_and_organizations
    articles = articles.tagged_with(tags, any: true).unscope(:select) if tags
    articles = articles.tagged_with(tags_exclude, exclude: true) if tags_exclude

    articles
      .order(public_reactions_count: :desc)
      .page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def top_articles
    published_articles_with_users_and_organizations
      .where("published_at > ?", top.to_i.days.ago)
      .order(public_reactions_count: :desc)
      .page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def state_articles(state)
    articles = published_articles_with_users_and_organizations

    articles = case state
               when "fresh"
                 articles.where(
                   "public_reactions_count < ? AND published_at > ? AND score > ?", 2, 7.hours.ago, -2
                 )
               when "rising"
                 articles.where(
                   "public_reactions_count > ? AND public_reactions_count < ? AND published_at > ?",
                   19, 33, 3.days.ago
                 )
               when "recent"
                 articles.order(published_at: :desc)
               else
                 Article.none
               end

    articles.page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def collection_articles(collection_id)
    published_articles_with_users_and_organizations
      .where(collection_id: collection_id)
      .order(:published_at)
      .page(page)
      .per(per_page || DEFAULT_PER_PAGE)
  end

  def sorted_articles(sort)
    # This could be expanded to allow additional sorting options
    if sort == "desc"
      published_articles_with_users_and_organizations
        .order(published_at: :desc)
        .page(page)
        .per(per_page || DEFAULT_PER_PAGE)
    else
      Article.none
    end
  end

  def base_articles
    published_articles_with_users_and_organizations
      .featured
      .order(hotness_score: :desc)
      .page(page)
      .per(per_page || DEFAULT_PER_PAGE)
  end

  def published_articles_with_users_and_organizations
    Article.published.from_subforem.includes([{ user: :profile }, :organization])
  end
end
