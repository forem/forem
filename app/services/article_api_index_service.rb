class ArticleApiIndexService
  DEFAULT_PER_PAGE = 30
  MAX_PER_PAGE = 1000

  def initialize(params)
    @page = params[:page]
    @tag = params[:tag]
    @tags = params[:tags]
    @tags_exclude = params[:tags_exclude]
    @username = params[:username]
    @state = params[:state]
    @sort = params[:sort]
    @top = params[:top]
    @collection_id = params[:collection_id]
    @per_page = params[:per_page]
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

  def username_articles
    num = if @state == "all"
            MAX_PER_PAGE
          else
            DEFAULT_PER_PAGE
          end

    if (user = User.find_by(username: username))
      user.articles.published
        .includes(:organization)
        .order(published_at: :desc)
        .page(page)
        .per(per_page || num)
    elsif (organization = Organization.find_by(slug: username))
      organization.articles.published
        .includes(:user)
        .order(published_at: :desc)
        .page(page)
        .per(per_page || num)
    else
      Article.none
    end
  end

  def tag_articles
    articles = Article.published.cached_tagged_with(tag).includes(:user, :organization)

    articles = if Tag.find_by(name: tag)&.requires_approval
                 articles.where(approved: true).order(featured_number: :desc)
               elsif top.present?
                 articles.where("published_at > ?", top.to_i.days.ago)
                   .order(public_reactions_count: :desc)
               else
                 articles.order(hotness_score: :desc)
               end

    articles.page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def tagged_articles
    articles = Article.published.includes(:user, :organization)
    articles = articles.tagged_with(tags, any: true).unscope(:select) if tags
    articles = articles.tagged_with(tags_exclude, exclude: true) if tags_exclude

    articles
      .order(public_reactions_count: :desc)
      .page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def top_articles
    Article.published.includes(:user, :organization)
      .where("published_at > ?", top.to_i.days.ago)
      .order(public_reactions_count: :desc)
      .page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def state_articles(state)
    articles = Article.published.includes(:user, :organization)

    articles = case state
               when "fresh"
                 articles.where(
                   "public_reactions_count < ? AND featured_number > ? AND score > ?", 2, 7.hours.ago.to_i, -2
                 )
               when "rising"
                 articles.where(
                   "public_reactions_count > ? AND public_reactions_count < ? AND featured_number > ?",
                   19, 33, 3.days.ago.to_i
                 )
               when "recent"
                 articles.order(published_at: :desc)
               else
                 Article.none
               end

    articles.page(page).per(per_page || DEFAULT_PER_PAGE)
  end

  def collection_articles(collection_id)
    Article.published
      .where(collection_id: collection_id)
      .includes(:user, :organization)
      .order(:published_at)
      .page(page)
      .per(per_page || DEFAULT_PER_PAGE)
  end

  def sorted_articles(sort)
    # This could be expanded to allow additional sorting options
    if sort == "desc"
      Article.published
        .includes(:user, :organization)
        .order(published_at: :desc)
        .page(page)
        .per(per_page || DEFAULT_PER_PAGE)
    else
      Article.none
    end
  end

  def base_articles
    Article.published
      .where(featured: true)
      .includes(:user, :organization)
      .order(hotness_score: :desc)
      .page(page)
      .per(per_page || DEFAULT_PER_PAGE)
  end
end
