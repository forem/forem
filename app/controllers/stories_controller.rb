class StoriesController < ApplicationController
  before_action :authenticate_user!, except: %i[index search show]
  before_action :set_cache_control_headers, only: %i[index search show]

  def index
    return handle_user_or_organization_or_podcast_or_page_index if params[:username]
    return handle_tag_index if params[:tag]

    handle_base_index
  end

  def search
    @query = "...searching"
    @article_index = true
    set_surrogate_key_header "articles-page-with-query"
    render template: "articles/search"
  end

  def show
    # TODO: validate input and mass assignment
    first_scope = params[:username]
    second_scope = params[:slug]
    article_by_path = Article.find_by(path: "/#{first_scope.downcase}/#{second_scope}")&.decorate
    article_by_slug = Article.find_by(slug: second_scope)&.decorate

    @story_show = true

    case url_format(article_by_path, article_by_slug)
    when 'author/article'
      result = Articles::Show.execute(article_by_path, moderate: params[:view] == "moderate",
                            variant_version: params[:variant_version],
                            previewing: params[:preview], user_signed_in: user_signed_in?)

      @presenter = result.article_presenter

      return redirect_to result.moderate_url if result.moderate_url

      set_surrogate_key_header @presenter.record_key

      render template: 'articles/show'
    when 'podcast/episode'
      episode_slug = second_scope
      podcast_provider = first_scope
      podcast = Podcast.available.find_by!(slug: podcast_provider)
      episode = PodcastEpisode.available.find_by!(slug: episode_slug).decorate

      @presenter = PodcastShowPresenter.new(podcast, episode)
      @comment = @presenter.comment

      set_surrogate_key_header episode.record_key

      render template: "podcast_episodes/show"
    when 'other'
      support_legacy_url_formats(article_by_slug)
    end
  end

  def warm_comments
    @article = Article.find_by(path: "/#{params[:username].downcase}/#{params[:slug]}")&.decorate || not_found
    @warm_only = true
    assign_article_show_variables
    render partial: "articles/full_comment_area"
  end

  private

  def url_format(article_by_path, article_by_slug)
    if article_by_path
      'author/article'
    elsif article_by_slug
      'other'
    else
      'podcast/episode'
    end
  end

  def support_legacy_url_formats(article)
    redirect_to try_to_find_url_for(article, params[:username], params[:slug])
  end

  def try_to_find_url_for(article, authorname, article_slug)
    # Search potential author considering old usernames
    potential_username = authorname.tr("@", "").downcase
    user = User.find_by("old_username = ? OR old_old_username = ?", potential_username, potential_username)
    return URI.parse("/#{user.username}/#{article_slug}").path if user&.articles&.find_by(slug: article_slug)

    # try to use article organization
    return URI.parse("/#{article.organization.slug}/#{article_slug}").path if article.organization

    raise ActiveRecord::RecordNotFound, "Not Found" # this is not covered by tests
  end

  def redirect_to_changed_username_profile
    potential_username = params[:username].tr("@", "").downcase
    user_or_org = User.find_by("old_username = ? OR old_old_username = ?", potential_username, potential_username) ||
      Organization.find_by("old_slug = ? OR old_old_slug = ?", potential_username, potential_username)
    if user_or_org.present?
      redirect_to user_or_org.path
      return
    else
      not_found
    end
  end

  def handle_user_or_organization_or_podcast_or_page_index
    @podcast = Podcast.available.find_by(slug: params[:username].downcase)
    @organization = Organization.find_by(slug: params[:username].downcase)
    @page = Page.find_by(slug: params[:username].downcase, is_top_level_path: true)
    if @podcast
      handle_podcast_index
    elsif @organization
      handle_organization_index
    elsif @page
      handle_page_display
    else
      handle_user_index
    end
  end

  def handle_tag_index
    @tag = params[:tag].downcase
    @page = (params[:page] || 1).to_i
    @tag_model = Tag.find_by(name: @tag) || not_found
    @moderators = User.with_role(:tag_moderator, @tag_model).select(:username, :profile_image, :id)
    if @tag_model.alias_for.present?
      redirect_to "/t/#{@tag_model.alias_for}"
      return
    end

    @stories = article_finder(8)

    @stories = @stories.where(approved: true) if @tag_model&.requires_approval

    @stories = stories_by_timeframe
    @stories = @stories.decorate

    @article_index = true
    set_surrogate_key_header "articles-#{@tag}"
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"
    render template: "articles/tag_index"
  end

  def handle_page_display
    @story_show = true
    set_surrogate_key_header "show-page-#{params[:username]}"
    render template: "pages/show"
  end

  def handle_base_index
    @home_page = true
    @page = (params[:page] || 1).to_i
    num_articles = 35
    @stories = article_finder(num_articles)
    if %w[week month year infinity].include?(params[:timeframe])
      @stories = @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("score DESC")
    elsif params[:timeframe] == "latest"
      @stories = @stories.order("published_at DESC").
        where("featured_number > ? AND score > ?", 1_449_999_999, -40)
      @featured_story = Article.new
    else
      @default_home_feed = true
      @stories = @stories.
        where("score > ? OR featured = ?", 9, true).
        order("hotness_score DESC")
      if user_signed_in?
        offset = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11].sample # random offset, weighted more towards zero
        @stories = @stories.offset(offset)
      end
    end
    assign_podcasts
    assign_classified_listings
    @article_index = true
    set_surrogate_key_header "main_app_home_page"
    response.headers["Surrogate-Control"] = "max-age=600, stale-while-revalidate=30, stale-if-error=86400"
    render template: "articles/index"
  end

  def handle_podcast_index
    @podcast_index = true
    @article_index = true
    @list_of = "podcast-episodes"
    @podcast_episodes = @podcast.podcast_episodes.
      reachable.order("published_at DESC").limit(30).decorate
    set_surrogate_key_header "podcast_episodes"
    render template: "podcast_episodes/index"
  end

  def handle_organization_index
    @user = @organization
    @stories = ArticleDecorator.decorate_collection(@organization.articles.published.
      limited_column_select.
      order("published_at DESC").page(@page).per(8))
    @article_index = true
    @organization_article_index = true
    set_surrogate_key_header "articles-org-#{@organization.id}"
    render template: "organizations/show"
  end

  def handle_user_index
    @user = User.find_by(username: params[:username].tr("@", "").downcase)
    unless @user
      redirect_to_changed_username_profile
      return
    end
    assign_user_comments
    @pinned_stories = Article.published.where(id: @user.profile_pins.select(:pinnable_id)).
      limited_column_select.
      order("published_at DESC").decorate
    @stories = ArticleDecorator.decorate_collection(@user.articles.published.
      limited_column_select.
      where.not(id: @pinned_stories.pluck(:id)).
      order("published_at DESC").page(@page).per(user_signed_in? ? 2 : 5))
    @article_index = true
    @list_of = "articles"
    redirect_if_view_param
    return if performed?

    set_surrogate_key_header "articles-user-#{@user.id}"
    render template: "users/show"
  end

  def redirect_if_view_param
    redirect_to "/internal/users/#{@user.id}" if params[:view] == "moderate"
    redirect_to "/admin/users/#{@user.id}/edit" if params[:view] == "admin"
  end

  def assign_article_show_variables
    @article_show = true
    @variant_number = params[:variant_version] || (user_signed_in? ? 0 : rand(2))
    assign_user_and_org
    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 50 : 30
    assign_second_and_third_user
    not_found if permission_denied?
    @comment = Comment.new(body_markdown: @article&.comment_template)
  end

  def permission_denied?
    !@article.published && params[:preview] != @article.password
  end

  def assign_user_and_org
    @user = @article.user || not_found
    @organization = @article.organization if @article.organization_id.present?
  end

  def assign_second_and_third_user
    return if @article.second_user_id.blank?

    @second_user = User.find(@article.second_user_id)
    @third_user = User.find(@article.third_user_id) if @article.third_user_id.present?
  end

  def assign_user_comments
    comment_count = params[:view] == "comments" ? 250 : 8
    @comments = if @user.comments_count.positive?
                  @user.comments.where(deleted: false).
                    order("created_at DESC").includes(:commentable).limit(comment_count)
                else
                  []
                end
  end

  def stories_by_timeframe
    if %w[week month year infinity].include?(params[:timeframe])
      @stories.where("published_at > ?", Timeframer.new(params[:timeframe]).datetime).
        order("positive_reactions_count DESC")
    elsif params[:timeframe] == "latest"
      @stories.where("score > ?", -40).order("published_at DESC")
    else
      @stories.order("hotness_score DESC")
    end
  end

  def assign_podcasts
    return unless user_signed_in?

    num_hours = Rails.env.production? ? 24 : 800
    @podcast_episodes = PodcastEpisode.
      includes(:podcast).
      order("published_at desc").
      where("published_at > ?", num_hours.hours.ago).
      select(:slug, :title, :podcast_id)
  end

  def assign_classified_listings
    @classified_listings = ClassifiedListing.where(published: true).select(:title, :category, :slug, :bumped_at)
  end

  def article_finder(num_articles)
    tag = params[:tag]
    articles = Article.published.limited_column_select.page(@page).per(num_articles)
    articles = articles.cached_tagged_with(tag) if tag.present? # More efficient than tagged_with
    articles
  end
end
