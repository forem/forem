class StoriesController < ApplicationController
  before_action :authenticate_user!, except: %i[index search show feed new]
  before_action :set_cache_control_headers, only: %i[index search show]

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
    if @article = Article.find_by_path("/#{params[:username].downcase}/#{params[:slug]}")&.decorate
      handle_article_show
    elsif @article = Article.find_by_slug(params[:slug])&.decorate
      handle_possible_redirect
    else
      @podcast = Podcast.find_by_slug(params[:username]) || not_found
      @episode = PodcastEpisode.find_by_slug(params[:slug]) || not_found
      handle_podcast_show
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

  def handle_possible_redirect
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
    if @organization = @article.organization
      redirect_to "/#{@organization.slug}/#{params[:slug]}"
      return
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

    @stories = article_finder(8)

    if @tag_model&.requires_approval
      @stories = @stories.where(approved: true)
    end

    @stories = stories_by_timeframe
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
    num_articles = 15
    @stories = article_finder(num_articles)

    if ["week", "month", "year", "infinity"].include?(params[:timeframe])
      @stories = @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("positive_reactions_count DESC")
      @featured_story = @stories.where.not(main_image: nil).first&.decorate || Article.new
    elsif params[:timeframe] == "latest"
      @stories = @stories.order("published_at DESC").
        where("featured_number > ? AND score > ?", 1449999999, -40)
      @featured_story = Article.new
    else
      @default_home_feed = true
      @stories = @stories.
        where("reactions_count > ? OR featured = ?", 10, true).
        order("hotness_score DESC")
      if user_signed_in?
        offset = [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7].sample #random offset, weighted more towards zero
        @stories = @stories.offset(offset)
      end
      @featured_story = @stories.where.not(main_image: nil).first&.decorate || Article.new
      if user_signed_in?
        @new_stories = Article.where("published_at > ? AND score > ?", 4.hours.ago, -30).
          where(published: true).
          includes(:user).
          limit(45).
          order("published_at DESC").
          limited_column_select.
          decorate
      end
    end
    @stories = @stories.decorate
    assign_podcasts
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
    @user = User.find_by_username(params[:username].tr("@", "").downcase)
    unless @user
      redirect_to_changed_username_profile
      return
    end
    assign_user_comments
    @stories = ArticleDecorator.decorate_collection(@user.
      articles.where(published: true).
      limited_column_select.
      order("published_at DESC").page(@page).per(user_signed_in? ? 2 : 5))
    @featured_story = Article.new
    @article_index = true
    @list_of = "articles"
    redirect_if_view_param
    return if performed?
    set_surrogate_key_header "articles-user-#{@user.id}", @stories.map(&:record_key)
    render template: "articles/index"
  end

  def handle_podcast_show
    set_surrogate_key_header @episode.record_key
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new
    render template: "podcast_episodes/show"
    nil
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
    assign_user_and_org
    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 65 : 35
    assign_second_and_third_user
    not_found if permission_denied?
    set_surrogate_key_header @article.record_key
    redirect_if_show_view_param
    return if performed?
    render template: "articles/show"
  end

  def permission_denied?
    !@article.published && params[:preview] != @article.password
  end

  def assign_user_and_org
    @user = @article.user || not_found
    @organization = @article.organization if @article.organization_id.present?
  end

  def assign_second_and_third_user
    if @article.second_user_id.present?
      @second_user = User.find(@article.second_user_id)
      if @article.third_user_id.present?
        @third_user = User.find(@article.third_user_id)
      end
    end
  end

  def assign_user_comments
    comment_count = params[:view] == "comments" ? 250 : 8
    @comments = if @user.comments_count > 0
                  @user.comments.where(deleted: false).
                    order("created_at DESC").includes(:commentable).limit(comment_count)
                else
                  []
                end
  end

  def stories_by_timeframe
    if ["week", "month", "year", "infinity"].include?(params[:timeframe])
      @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("positive_reactions_count DESC")
    elsif params[:timeframe] == "latest"
      @stories.where("score > ?", -40).order("published_at DESC")
    else
      @stories.order("hotness_score DESC")
    end
  end

  def assign_podcasts
    if user_signed_in?
      @podcast_episodes = PodcastEpisode.
        includes(:podcast).
        order("published_at desc").
        select(:slug, :title, :podcast_id).limit(5)
    end
  end

  def article_finder(num_articles)
    Article.where(published: true).
      includes(:user).
      limited_column_select.
      page(@page).
      per(num_articles).
      filter_excluded_tags(params[:tag])
  end
end
