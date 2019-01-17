class ArticleApiIndexService
  attr_accessor :tag, :username, :page, :state, :top
  def initialize(params)
    @page =     params[:page]
    @tag =      params[:tag]
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
               else
                 base_articles
               end
    articles.
      decorate
  end

  private

  def username_articles
    num = if @state == "all"
            1000
          else
            30
          end
    if user = User.find_by_username(username)
      user.articles.
        where(published: true).
        includes(:user).
        order("published_at DESC").
        page(page).
        per(num)
    elsif organization = Organization.find_by_slug(username)
      organization.articles.
        where(published: true).
        includes(:user).
        order("published_at DESC").
        page(page).
        per(num)
    else
      not_found
    end
  end

  def tag_articles
    if Tag.find_by_name(tag)&.requires_approval
      Article.
        where(published: true, approved: true).
        order("featured_number DESC").
        includes(:user).
        includes(:organization).
        page(page).
        per(30).
        filter_excluded_tags(tag)
    elsif top.present?
      Article.
        where(published: true).
        order("positive_reactions_count DESC").
        where("published_at > ?", top.to_i.days.ago).
        includes(:user).
        includes(:organization).
        page(page).
        per(30).
        filter_excluded_tags(tag)
    else
      Article.
        where(published: true).
        order("hotness_score DESC").
        includes(:user).
        includes(:organization).
        page(page).
        per(30).
        filter_excluded_tags(tag)
    end
  end

  def state_articles(state)
    if state == "fresh"
      Article.where(published: true).
        where("positive_reactions_count < ? AND featured_number > ? AND score > ?", 2, 7.hours.ago.to_i, -2)
    elsif state == "rising"
      Article.where(published: true).
        where("positive_reactions_count > ? AND positive_reactions_count < ? AND featured_number > ?", 19, 33, 3.days.ago.to_i)
    end
  end

  def base_articles
    Article.
      where(published: true, featured: true).
      order("hotness_score DESC").
      includes(:user).
      includes(:organization).
      page(page).
      per(30)
  end
end
