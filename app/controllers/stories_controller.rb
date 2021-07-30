class StoriesController < ApplicationController
  helper ProfileHelper

  DEFAULT_HOME_FEED_ATTRIBUTES_FOR_SERIALIZATION = {
    only: %i[
      title path id user_id comments_count public_reactions_count organization_id
      reading_time video_thumbnail_url video video_duration_in_minutes
      experience_level_rating experience_level_rating_distribution cached_user cached_organization
      listing_category_id
    ],
    methods: %i[
      readable_publish_date cached_tag_list_array flare_tag class_name
      cloudinary_video_url video_duration_in_minutes published_at_int published_timestamp
    ]
  }.freeze

  SIGNED_OUT_RECORD_COUNT = 60

  before_action :authenticate_user!, except: %i[index search show]
  before_action :set_cache_control_headers, only: %i[index search show]
  before_action :redirect_to_lowercase_username, only: %i[index]

  rescue_from ArgumentError, with: :bad_request

  def index
    @page = (params[:page] || 1).to_i
    @article_index = true

    return handle_user_or_organization_or_podcast_or_page_index if params[:username]

    handle_base_index
  end

  def search
    @query = "...searching"
    @article_index = true
    @current_ordering = current_search_results_ordering
    set_surrogate_key_header "articles-page-with-query"
    render template: "articles/search"
  end

  def show
    @story_show = true
    if (@article = Article.find_by(path: "/#{params[:username].downcase}/#{params[:slug]}")&.decorate)
      handle_article_show
    elsif (@article = Article.find_by(slug: params[:slug])&.decorate)
      handle_possible_redirect
    else
      @podcast = Podcast.available.find_by!(slug: params[:username])
      @episode = @podcast.podcast_episodes.available.find_by!(slug: params[:slug])
      handle_podcast_show
    end
  end

  private

  def assign_hero_html
    return if Campaign.current.hero_html_variant_name.blank?

    @hero_area = HtmlVariant.relevant.select(:name, :html)
      .find_by(group: "campaign", name: Campaign.current.hero_html_variant_name)
    @hero_html = @hero_area&.html
  end

  def get_latest_campaign_articles
    campaign_articles_scope = Article.tagged_with(Campaign.current.featured_tags, any: true)
      .where("published_at > ? AND score > ?", Settings::Campaign.articles_expiry_time.weeks.ago, 0)
      .order(hotness_score: :desc)

    requires_approval = Campaign.current.articles_require_approval?
    campaign_articles_scope = campaign_articles_scope.where(approved: true) if requires_approval

    @campaign_articles_count = campaign_articles_scope.count
    @latest_campaign_articles = campaign_articles_scope.limit(5).pluck(:path, :title, :comments_count, :created_at)
  end

  def redirect_to_changed_username_profile
    potential_username = params[:username].tr("@", "")
    user_or_org = User.find_by("old_username = ? OR old_old_username = ?", potential_username, potential_username) ||
      Organization.find_by("old_slug = ? OR old_old_slug = ?", potential_username, potential_username)
    if user_or_org.present? && !user_or_org.decorate.fully_banished?
      redirect_permanently_to(user_or_org.path)
    else
      not_found
    end
  end

  def handle_possible_redirect
    if @article.organization
      redirect_permanently_to(@article.path)
      return
    end

    potential_username = params[:username].tr("@", "").downcase
    @user = User.find_by("old_username = ? OR old_old_username = ?", potential_username, potential_username)
    if @user&.articles&.find_by(slug: params[:slug])
      redirect_permanently_to(URI.parse("/#{@user.username}/#{params[:slug]}").path)
      return
    end

    not_found
  end

  def handle_user_or_organization_or_podcast_or_page_index
    @podcast = Podcast.available.find_by(slug: params[:username])
    @organization = Organization.find_by(slug: params[:username])
    @page = Page.find_by(slug: params[:username], is_top_level_path: true)
    if @podcast
      Honeycomb.add_field("stories_route", "podcast")
      handle_podcast_index
    elsif @organization
      Honeycomb.add_field("stories_route", "org")
      handle_organization_index
    elsif @page
      if FeatureFlag.accessible?(@page.feature_flag_name, current_user)
        Honeycomb.add_field("stories_route", "page")
        handle_page_display
      else
        not_found
      end
    else
      Honeycomb.add_field("stories_route", "user")
      handle_user_index
    end
  end

  def handle_page_display
    @story_show = true
    set_surrogate_key_header "show-page-#{params[:username]}"

    if @page.template == "json"
      render json: @page.body_json
    else
      render template: "pages/show"
    end
  end

  def handle_base_index
    @home_page = true
    assign_feed_stories unless user_signed_in? # Feed fetched async for signed-in users
    assign_hero_html
    assign_podcasts
    get_latest_campaign_articles if Campaign.current.show_in_sidebar?
    @article_index = true
    set_surrogate_key_header "main_app_home_page"
    set_cache_control_headers(600,
                              stale_while_revalidate: 30,
                              stale_if_error: 86_400)

    render template: "articles/index"
  end

  def pinned_article
    @pinned_article ||= PinnedArticle.get
  end

  def featured_story
    @featured_story ||= Articles::Feeds::LargeForemExperimental.find_featured_story(@stories)
  end

  def handle_podcast_index
    @podcast_index = true
    @list_of = "podcast-episodes"
    @podcast_episodes = @podcast.podcast_episodes
      .reachable.order(published_at: :desc).limit(30).decorate
    set_surrogate_key_header "podcast_episodes"
    render template: "podcast_episodes/index"
  end

  def handle_organization_index
    @user = @organization
    @stories = ArticleDecorator.decorate_collection(@organization.articles.published
      .limited_column_select
      .order(published_at: :desc).page(@page).per(8))
    @organization_article_index = true
    set_organization_json_ld
    set_surrogate_key_header "articles-org-#{@organization.id}"
    render template: "organizations/show"
  end

  def handle_user_index
    @user = User.find_by(username: params[:username].tr("@", ""))
    unless @user
      redirect_to_changed_username_profile
      return
    end
    not_found if @user.username.include?("spam_") && @user.decorate.fully_banished?
    not_found unless @user.registered
    assign_user_comments
    assign_user_stories
    @list_of = "articles"
    redirect_if_view_param
    return if performed?

    assign_user_github_repositories

    # @badges_limit is here and is set to 6 because it determines how many badges we will display
    # on Profile sidebar widget. If user has more badges, we hide them and let them be revealed
    # by clicking "See more" button (because we want to save space etc..). But why 6 exactly?
    # To make that widget look good:
    #   - On desktop it will have 3 rows, each row with 2 badges.
    #   - On mobile it will have 2 rows, each row with 3 badges.
    # So it's always 6. If we make it higher or lower number, we would have to sacrifice UI:
    #   - Let's say it's `4`. On mobile it would display two rows: 1st with 3 badges and
    # 2nd with 1 badge (!) <-- and that would look off.
    @badges_limit = 6
    @profile = @user.profile.decorate
    @is_user_flagged = Reaction.where(user_id: session_current_user_id, reactable: @user).any?

    set_surrogate_key_header "articles-user-#{@user.id}"
    set_user_json_ld

    render template: "users/show"
  end

  def handle_podcast_show
    set_surrogate_key_header @episode.record_key
    @episode = @episode.decorate
    @podcast_episode_show = true
    @comments_to_show_count = 25
    @comment = Comment.new
    render template: "podcast_episodes/show"
    nil
  end

  def redirect_if_view_param
    redirect_to admin_user_path(@user.id) if params[:view] == "moderate"
    redirect_to edit_admin_user_path(@user.id) if params[:view] == "admin"
  end

  def redirect_if_show_view_param
    redirect_to admin_article_path(@article.id) if params[:view] == "moderate"
  end

  def handle_article_show
    assign_article_show_variables
    set_surrogate_key_header @article.record_key
    redirect_if_show_view_param
    return if performed?

    render template: "articles/show"
  end

  def assign_feed_stories
    feed = Articles::Feeds::LargeForemExperimental.new(page: @page, tag: params[:tag])

    if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
      @stories = feed.top_articles_by_timeframe(timeframe: params[:timeframe])
    elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
      @stories = feed.latest_feed
    else
      @default_home_feed = true
      @featured_story, @stories = feed.default_home_feed_and_featured_story(user_signed_in: user_signed_in?)
    end

    @pinned_article = pinned_article&.decorate
    @featured_story = (featured_story || Article.new)&.decorate

    @stories = ArticleDecorator.decorate_collection(@stories)
  end

  def assign_article_show_variables
    not_found if permission_denied?
    not_found unless @article.user

    @pinned_article_id = PinnedArticle.id

    @article_show = true

    @discussion_lock = @article.discussion_lock
    @user = @article.user
    @organization = @article.organization

    if @article.collection
      @collection = @article.collection

      # we need to make sure that articles that were cross posted after their
      # original publication date appear in the correct order in the collection,
      # considering non cross posted articles with a more recent publication date
      @collection_articles = @article.collection.articles
        .published
        .order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
    end

    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 50 : 30
    set_article_json_ld
    assign_co_authors
    @comment = Comment.new(body_markdown: @article&.comment_template)
  end

  def permission_denied?
    !@article.published && params[:preview] != @article.password
  end

  def assign_co_authors
    return if @article.co_author_ids.blank?

    @co_author_ids = User.find(@article.co_author_ids)
  end

  def assign_user_comments
    comment_count = helpers.comment_count(params[:view])
    @comments = if @user.comments_count.positive?
                  @user.comments.where(deleted: false)
                    .order(created_at: :desc).includes(:commentable).limit(comment_count)
                else
                  []
                end
  end

  def assign_user_stories
    @pinned_stories = Article.published.where(id: @user.profile_pins.select(:pinnable_id))
      .limited_column_select
      .order(published_at: :desc).decorate
    @stories = ArticleDecorator.decorate_collection(@user.articles.published
      .limited_column_select
      .where.not(id: @pinned_stories.map(&:id))
      .order(published_at: :desc).page(@page).per(user_signed_in? ? 2 : SIGNED_OUT_RECORD_COUNT))
  end

  def assign_user_github_repositories
    @github_repositories = @user.github_repos.featured.order(stargazers_count: :desc, name: :asc)
  end

  def assign_podcasts
    return unless user_signed_in?

    @podcast_episodes = PodcastEpisode
      .includes(:podcast)
      .order(published_at: :desc)
      .where("published_at > ?", 24.hours.ago)
      .select(:slug, :title, :podcast_id, :image)
  end

  def redirect_to_lowercase_username
    return unless params[:username] && params[:username]&.match?(/[[:upper:]]/)

    redirect_permanently_to("/#{params[:username].downcase}")
  end

  def set_user_json_ld
    # For more info on structuring data with JSON-LD,
    # please refer to this link: https://moz.com/blog/json-ld-for-beginners
    @user_json_ld = {
      "@context": "http://schema.org",
      "@type": "Person",
      mainEntityOfPage: {
        "@type": "WebPage",
        "@id": URL.user(@user)
      },
      url: URL.user(@user),
      sameAs: user_same_as,
      image: Images::Profile.call(@user.profile_image_url, length: 320),
      name: @user.name,
      email: @user.setting.display_email_on_profile ? @user.email : nil,
      description: @user.profile.summary.presence || "404 bio not found",
      alumniOf: @user.education.presence
    }.reject { |_, v| v.blank? }
  end

  def set_article_json_ld
    @article_json_ld = {
      "@context": "http://schema.org",
      "@type": "Article",
      mainEntityOfPage: {
        "@type": "WebPage",
        "@id": URL.article(@article)
      },
      url: URL.article(@article),
      image: seo_optimized_images,
      publisher: {
        "@context": "http://schema.org",
        "@type": "Organization",
        name: Settings::Community.community_name.to_s,
        logo: {
          "@context": "http://schema.org",
          "@type": "ImageObject",
          url: ApplicationController.helpers.optimized_image_url(Settings::General.logo_png, width: 192,
                                                                                             fetch_format: "png"),
          width: "192",
          height: "192"
        }
      },
      headline: @article.title,
      author: {
        "@context": "http://schema.org",
        "@type": "Person",
        url: URL.user(@user),
        name: @user.name
      },
      datePublished: @article.published_timestamp,
      dateModified: @article.edited_at&.iso8601 || @article.published_timestamp
    }
  end

  def seo_optimized_images
    # This array of images exists for SEO optimization purposes.
    # For more info on this structure, please refer to this documentation:
    # https://developers.google.com/search/docs/data-types/article
    [
      ApplicationController.helpers.article_social_image_url(@article, width: 1080, height: 1080),
      ApplicationController.helpers.article_social_image_url(@article, width: 1280, height: 720),
      ApplicationController.helpers.article_social_image_url(@article, width: 1600, height: 900),
    ]
  end

  def set_organization_json_ld
    @organization_json_ld = {
      "@context": "http://schema.org",
      "@type": "Organization",
      mainEntityOfPage: {
        "@type": "WebPage",
        "@id": URL.organization(@organization)
      },
      url: URL.organization(@organization),
      image: Images::Profile.call(@organization.profile_image_url, length: 320),
      name: @organization.name,
      description: @organization.summary.presence || "404 bio not found"
    }
  end

  def user_same_as
    # For further information on the sameAs property, please refer to this link:
    # https://schema.org/sameAs
    [
      @user.twitter_username.present? ? "https://twitter.com/#{@user.twitter_username}" : nil,
      @user.github_username.present? ? "https://github.com/#{@user.github_username}" : nil,
      @user.profile.website_url,
    ].reject(&:blank?)
  end

  def current_search_results_ordering
    return :relevance unless params[:sort_by] == "published_at" && params[:sort_direction].present?

    params[:sort_direction] == "desc" ? :newest : :oldest
  end
end
