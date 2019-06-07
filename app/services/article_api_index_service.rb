class ArticleApiIndexService
  attr_accessor :tag, :username, :page, :state, :top

  def initialize(params)
    @page = params[:page]
    @tag = params[:tag]
    @username = params[:username]
    @state = params[:state]
    @top = params[:top]
  end

  def get
    articles = if tag.present?
                 tag_articles
               elsif username.present?
                 username_articles
               elsif state.present?
                 state_articles(state)
               elsif top.present?
                 top_articles
               else
                 base_articles
               end

    articles.decorate
  end

  private

  def username_articles
    num = if @state == "all"
            1000
          else
            30
          end

    if (user = User.find_by(username: username))
      user.articles.published.
        includes(:organization).
        order("published_at DESC").
        page(page).
        per(num)
    elsif (organization = Organization.find_by(slug: username))
      organization.articles.published.
        includes(:user).
        order("published_at DESC").
        page(page).
        per(num)
    else
      Article.none
    end
  end

  def tag_articles
    articles = Article.published.cached_tagged_with(tag).includes(:user, :organization)

    articles = if Tag.find_by(name: tag)&.requires_approval
                 articles.where(approved: true).order("featured_number DESC")
               elsif top.present?
                 articles.where("published_at > ?", top.to_i.days.ago).
                   order("positive_reactions_count DESC")
               else
                 articles.order("hotness_score DESC")
               end

    articles.page(page).per(30)
  end

  def top_articles
    Article.published.order("positive_reactions_count DESC").where("published_at > ?", top.to_i.days.ago).
      page(page).per(30)
  end

  def state_articles(state)
    if state == "fresh"
      Article.published.
        where("positive_reactions_count < ? AND featured_number > ? AND score > ?", 2, 7.hours.ago.to_i, -2)
    elsif state == "rising"
      Article.published.
        where("positive_reactions_count > ? AND positive_reactions_count < ? AND featured_number > ?", 19, 33, 3.days.ago.to_i)
    end
  end

  def base_articles
    Article.published.
      where(featured: true).
      includes(:user, :organization).
      order("hotness_score DESC").
      page(page).
      per(30)
  end
end
