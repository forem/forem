class StoriesController < ApplicationController
  before_action :authenticate_user!, except: [:index,:search,:show,:amp, :feed, :new]
  before_action :set_cache_control_headers, only: [:index, :search, :show]

  skip_before_action :ensure_signup_complete

  layout "amp", only: [:amp]

  def index
    return handle_user_or_organization_or_podcast_index if params[:username]
    return handle_tag_index if params[:tag]
    handle_base_index
  end

  def search
    @query = "...searching"
    @stories = Article.none
    @featured_story = Article.new
    @article_index = true
    set_surrogate_key_header "articles-page-with-query"
    render template: "articles/index"
  end

  def show
    @story_show = true
    @podcast = Podcast.find_by_slug(params[:username])
    @episode = PodcastEpisode.find_by_slug(params[:slug])
    if @podcast && @episode
      handle_podcast_show
    else
      handle_article_show
    end
  end

  private

  def redirect_to_changed_username_profile
    if @user = User.find_by_old_username(params[:username].tr("@", "").downcase)
      redirect_to @user.path
      return
    end
    if @user = User.find_by_old_old_username(params[:username].tr("@", "").downcase)
      redirect_to @user.path
      return
    end
    not_found
  end

  def redirect_to_changed_username_article_page
    if @user = User.find_by_old_username(params[:username].tr("@", "").downcase)
      if @user.articles.find_by_slug(params[:slug])
        redirect_to "/#{@user.username}/#{params[:slug]}"
        return
      end
    end
    if @user = User.find_by_old_old_username(params[:username].tr("@", "").downcase)
      if @user.articles.find_by_slug(params[:slug])
        redirect_to "/#{@user.username}/#{params[:slug]}"
        return
      end
    end
    not_found
  end

  def handle_user_or_organization_or_podcast_index
    @podcast = Podcast.find_by_slug(params[:username].downcase)
    @organization = Organization.find_by_slug(params[:username].downcase)
    if @podcast
      handle_podcast_index
    elsif @organization
      handle_organization_index
    else
      handle_user_index
    end
  end

  def handle_tag_index
    @tag = params[:tag].downcase
    @page = (params[:page] || 1).to_i
    @tag_model = Tag.find_by_name(@tag) || not_found
    if @tag_model.alias_for.present?
      redirect_to "/t/#{@tag_model.alias_for}"
      return
    end
    @stories = Article.where(published: true).
      includes(:user).
      limited_column_select.
      page(@page).
      per(8).
      filter_excluded_tags(@tag)

    if @tag_model && @tag_model.requires_approval
      @stories = @stories.where(approved: true)
    end

    if ["week", "month", "year", "infinity"].include?(params[:timeframe])
      @stories = @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("positive_reactions_count DESC")
    elsif params[:timeframe] == "latest"
      @stories = @stories.order("published_at DESC")
    else
      @stories = @stories.order("hotness_score DESC")
    end

    @stories = @stories.decorate

    @featured_story = Article.new
    @article_index = true
    set_surrogate_key_header "articles-#{@tag}", @stories.map(&:record_key)
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"
    render template: "articles/index"
  end

  def handle_base_index
    @home_page = true
    @page = (params[:page] || 1).to_i
    num_articles = user_signed_in? ? 3 : 15
    @stories = Article.where(published: true).
      includes(:user).
      limited_column_select.
      page(@page).
      per(num_articles).
      filter_excluded_tags(params[:tag])
    if ["week", "month", "year", "infinity"].include?(params[:timeframe])
      @stories = @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("positive_reactions_count DESC")
      @featured_story = @stories.where.not(main_image: nil).first&.decorate || Article.new
    elsif params[:timeframe] == "latest"
      @stories = @stories.order("published_at DESC").
        where("featured_number > ?", 1449999999)
      @featured_story = Article.new
    else
      @stories = @stories.where(featured: true).order("hotness_score DESC")
      @featured_story = @stories.where.not(main_image: nil).first&.decorate || Article.new
    end
    @stories = @stories.decorate
    @podcast_episodes = PodcastEpisode.
      includes(:podcast).
      order("published_at desc").
      select(:slug, :title, :podcast_id).limit(5)
    @article_index = true
    @sidebar_ad = DisplayAd.where(approved: true, published: true, placement_area: "sidebar").first
    set_surrogate_key_header "articles", @stories.map(&:record_key)
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"
    render template: "articles/index"
  end

  def handle_podcast_index
    @featured_story = Article.new
    @podcast_index = true
    @article_index = true
    @list_of = "podcast-episodes"
    @podcast_episodes = @podcast.podcast_episodes.order("published_at DESC").limit(30)
    set_surrogate_key_header "podcast_episodes", (@podcast_episodes.map { |e| e["record_key"] })
    render template: "articles/index"
  end

  def handle_organization_index
    @user = @organization
    @stories = ArticleDecorator.decorate_collection(@organization.articles.
      where(published: true).
      limited_column_select.
      includes(:user).
      order("published_at DESC").page(@page).per(8))
    @featured_story = Article.new
    @article_index = true
    @organization_article_index = true
    set_surrogate_key_header "articles-org-#{@organization.id}", @stories.map(&:record_key)
    render template: "articles/index"
  end

  def handle_user_index
    @user = User.find_by_username(params[:username].tr("@","").downcase)
    unless @user
      redirect_to_changed_username_profile
      return
    end
    comment_count = params[:view] == "comments" ? 250 : 8
    @comments = @user.comments.where(deleted: false).
      order("created_at DESC").includes(:commentable).limit(comment_count)
    @stories = ArticleDecorator.decorate_collection(@user.
      articles.where(published: true).
      limited_column_select.
      order("published_at DESC").page(@page).per(user_signed_in? ? 2 : 5))
    @featured_story = Article.new
    @article_index = true
    @list_of = "articles"
    redirect_if_view_param; return if performed?
    set_surrogate_key_header "articles-user-#{@user.id}", @stories.map(&:record_key)
    render template: "articles/index"
  end

  def handle_podcast_show
    set_surrogate_key_header @episode.record_key
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new
    render template: "podcast_episodes/show"
    return
  end

  def redirect_if_view_param
    if params[:view] == "moderate"
      redirect_to "/internal/users/#{@user.id}/edit"
    end
    if params[:view] == "admin"
      redirect_to "/admin/users/#{@user.id}/edit"
    end
  end

  def redirect_if_show_view_param
    if params[:view] == "moderate"
      redirect_to "/internal/articles/#{@article.id}"
    end
  end

  def handle_article_show
    @article_show = true
    @comment = Comment.new
    assign_article_and_user_and_organization
    handle_possible_redirect; return if performed?
    not_found unless @article
    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 75 : 25
    assign_second_and_third_user
    not_found if permission_denied?
    set_surrogate_key_header @article.record_key
    @classic_article = ClassicArticle.new(@article).get
    unless user_signed_in?
      response.headers["Surrogate-Control"] = "max-age=10000, stale-while-revalidate=30, stale-if-error=86400"
    end
    redirect_if_show_view_param; return if performed?
    render template: "articles/show"
  end

  def permission_denied?
    !@article.published && params[:preview] != @article.password
  end

  def assign_article_and_user_and_organization
    @organization = Organization.find_by_slug(params[:username].downcase)
    @organization ? assign_organization_article : assign_user_article
  end

  def assign_second_and_third_user
    if @article.second_user_id.present?
      @second_user = User.find(@article.second_user_id)
      if @article.third_user_id.present?
        @third_user = User.find(@article.third_user_id)
      end
    end
  end

  def handle_possible_redirect
    if !@user && !@organization
      redirect_to_changed_username_article_page
    end
    if @article&.organization.present? && @organization.blank?
      redirect_to @article.path
    end
  end

  def assign_organization_article
    @article = @organization.articles.find_by_slug(params[:slug])&.decorate
    @user = @article&.user || not_found #The org may have changed back to user and this does not handle that properly
  end

  def assign_user_article
    @user = User.find_by_username(params[:username].downcase)
    return unless @user
    @article = @user.
      articles.
      find_by_slug(params[:slug])&.
      decorate
  end

end
