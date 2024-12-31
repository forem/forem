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
  REDIRECT_VIEW_PARAMS = %w[moderate admin].freeze

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_cache_control_headers, only: %i[index show]
  before_action :set_user_limit, only: %i[index show]
  before_action :redirect_to_lowercase_username, only: %i[index]

  rescue_from ArgumentError, with: :bad_request

  def index
    @page = (params[:page] || 1).to_i
    return handle_user_or_organization_or_podcast_or_page_index if params[:username]

    handle_base_index
  end

  def show
    @story_show = true
    path = "/#{params[:username].downcase}/#{params[:slug]}"
    if (@article = Article.includes(:user).find_by(path: path)&.decorate)
      handle_article_show
    elsif (@article = Article.find_by(slug: params[:slug])&.decorate)
      handle_possible_redirect
    elsif (@podcast = Podcast.available.find_by(slug: params[:username]))
      @episode = @podcast.podcast_episodes.available.find_by!(slug: params[:slug])
      handle_podcast_show
    elsif (@page = Page.find_by(slug: "#{params[:username]}/#{params[:slug]}", is_top_level_path: true))
      handle_page_display
    else
      not_found
    end
  end

  private

  # for spam content we need to remove cache control headers to access current_user to check admin access
  # so that admins could have access to spam articles and profiles
  def check_admin_access
    unset_cache_control_headers if user_signed_in?
    is_admin = user_signed_in? && current_user&.any_admin?
    not_found unless is_admin
  end

  def set_user_limit
    @user_limit = 50
  end

  def assign_hero_banner
    @hero_billboard = Billboard.for_display(area: "home_hero", user_signed_in: user_signed_in?)
  end

  def assign_hero_html
    return if Campaign.current.hero_html_variant_name.blank?

    @hero_area = HtmlVariant.relevant.select(:name, :html)
      .find_by(group: "campaign", name: Campaign.current.hero_html_variant_name)
    @hero_html = @hero_area&.html
  end

  def get_latest_campaign_articles
    @campaign_articles_count = Campaign.current.count
    @latest_campaign_articles = Campaign.current.plucked_article_attributes
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
      redirect_permanently_to(Addressable::URI.parse("/#{@user.username}/#{params[:slug]}").path)
      return
    end

    not_found
  end

  def handle_user_or_organization_or_podcast_or_page_index
    @podcast = Podcast.available.find_by(slug: params[:username])
    @organization = Organization.find_by(slug: params[:username])
    @page = Page.find_by(slug: params[:username], is_top_level_path: true)
    if @podcast
      handle_podcast_index
    elsif @organization
      handle_organization_index
    elsif @page
      if FeatureFlag.accessible?(@page.feature_flag_name, current_user)
        handle_page_display
      else
        not_found
      end
    else
      handle_user_index
    end
  end

  def handle_page_display
    redirect_page_if_different_subforem
    return if performed?

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
    assign_hero_banner
    assign_hero_html
    assign_podcasts
    get_latest_campaign_articles if Campaign.current.show_in_sidebar?

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
    @featured_story ||= Articles::Feeds::FindFeaturedStory.call(@stories)
  end

  def handle_podcast_index
    @podcast_index = true
    @list_of = "podcast-episodes"
    @podcast_episodes = @podcast.podcast_episodes
      .reachable.order(published_at: :desc).page(params[:page]).per(30)
    set_surrogate_key_header "podcast_episodes"
    render template: "podcast_episodes/index"
  end

  def handle_organization_index
    @user = @organization
    @stories = ArticleDecorator.decorate_collection(@organization.articles.published.from_subforem
      .includes(:distinct_reaction_categories, :subforem)
      .limited_column_select
      .order(published_at: :desc).page(@page).per(8))
    @organization_article_index = true
    @organization_users = @organization.users.order(badge_achievements_count: :desc)
    if !user_signed_in? && @organization_users.sum(:score).negative? && @stories.sum(&:score) <= 0
      not_found
    end
    redirect_if_inactive_in_subforem_for_organization
    return if performed?

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

    check_admin_access if @user.spam?

    if !user_signed_in? && (@user.suspended? && @user.has_no_published_content?)
      not_found
    end
    assign_user_comments
    assign_user_stories
    @list_of = "articles"
    redirect_if_view_param
    return if performed?

    redirect_if_inactive_in_subforem_for_user
    return if performed?

    assign_user_github_repositories

    @grouped_badges = @user.badge_achievements.order(id: :desc).includes(:badge).group_by(&:badge_id)
    @profile = @user&.profile&.decorate || Profile.create(user: @user)&.decorate
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
    redirect_to admin_user_path(@user.id) if REDIRECT_VIEW_PARAMS.include?(params[:view])
  end

  def redirect_if_inactive_in_subforem_for_user
    return unless @comments.none? &&
                    @pinned_stories.none? &&
                    @stories.none? &&
                    RequestStore.store[:subforem_id] != RequestStore.store[:default_subforem_id]

    subforem = Subforem.find(RequestStore.store[:default_subforem_id])
    redirect_to URL.url(@user.username, subforem), allow_other_host: true, status: :moved_permanently
  end

  def redirect_if_inactive_in_subforem_for_organization
    return unless @stories.none? &&
                    RequestStore.store[:subforem_id] != RequestStore.store[:default_subforem_id]
    
    subforem = Subforem.find(RequestStore.store[:default_subforem_id])
    redirect_to URL.url(@organization.slug, subforem), allow_other_host: true, status: :moved_permanently
  end

  def redirect_if_appropriate
    if should_redirect_to_subforem?(@article)
      redirect_to URL.article(@article), allow_other_host: true, status: :moved_permanently
    end
    redirect_to admin_article_path(@article.id) if params[:view] == "moderate"
  end

  def handle_article_show
    assign_article_show_variables
    set_surrogate_key_header @article.record_key
    redirect_if_appropriate
    return if performed?

    render template: "articles/show"
  end

  def assign_feed_stories
    if params[:timeframe].in?(Timeframe::FILTER_TIMEFRAMES)
      @stories = Articles::Feeds::Timeframe.call(params[:timeframe])
    elsif params[:timeframe] == Timeframe::LATEST_TIMEFRAME
      @stories = Articles::Feeds::Latest.call(minimum_score: Settings::UserExperience.home_feed_minimum_score)
    else
      @default_home_feed = true
      feed = Articles::Feeds::LargeForemExperimental.new(page: @page, tag: params[:tag])
      @featured_story, @stories = feed.featured_story_and_default_home_feed(user_signed_in: user_signed_in?)
      @stories = @stories.to_a
    end

    @pinned_article = pinned_article&.decorate
    @featured_story = (featured_story || Article.new)&.decorate

    @stories = ArticleDecorator.decorate_collection(@stories)
  end

  def assign_article_show_variables
    not_found if permission_denied?
    not_found unless @article.user

    check_admin_access if @article.user.spam?

    @pinned_article_id = PinnedArticle.id

    @article_show = true

    @discussion_lock = @article.discussion_lock
    @user = @article.user
    @organization = @article.organization
    @comments_order = fetch_sort_order

    @comments_count = Comments::Count.call(@article)

    if @article.collection
      @collection = @article.collection

      # we need to make sure that articles that were cross posted after their
      # original publication date appear in the correct order in the collection,
      # considering non cross posted articles with a more recent publication date
      @collection_articles = @article.collection.articles
        .published.from_subforem
        .order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
    end

    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 50 : 30
    @comments_to_show_count = 10 unless user_signed_in?
    set_article_json_ld
    assign_co_authors
    @comment = Comment.new(body_markdown: @article&.comment_template)
  end

  def permission_denied?
    (!@article.published || @article.scheduled?) && params[:preview] != @article.password
  end

  def assign_co_authors
    return if @article.co_author_ids.blank?

    @co_author_ids = User.find(@article.co_author_ids)
  end

  def assign_user_comments
    comment_count = helpers.comment_count(params[:view])
    @comments = []
    return unless user_signed_in? && @user.comments_count.positive?

    @comments = @user.comments.good_quality.where(deleted: false)
      .joins("INNER JOIN articles ON articles.id = comments.commentable_id AND comments.commentable_type = 'Article'")
      .merge(Article.from_subforem)
      .order(created_at: :desc)
      .includes(commentable: [:podcast])
      .limit(comment_count)
  end

  def assign_user_stories
    @pinned_stories = Article.published.from_subforem.full_posts.where(id: @user.profile_pins.select(:pinnable_id))
      .limited_column_select
      .order(published_at: :desc).decorate
    @stories = ArticleDecorator.decorate_collection(@user.articles.published.from_subforem.full_posts
      .includes(:distinct_reaction_categories, :subforem)
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
    return unless params[:username]&.match?(/[[:upper:]]/)

    redirect_permanently_to(action: :index, username: params[:username].downcase)
  end

  def set_user_json_ld
    # For more info on structuring data with JSON-LD,
    # please refer to this link: https://moz.com/blog/json-ld-for-beginners
    decorated_user = @user.decorate
    @user_json_ld = {
      "@context": "http://schema.org",
      "@type": "Person",
      mainEntityOfPage: {
        "@type": "WebPage",
        "@id": URL.user(@user)
      },
      url: URL.user(@user),
      sameAs: user_same_as,
      image: @user.profile_image_url_for(length: 320),
      name: @user.name,
      email: decorated_user.profile_email,
      description: decorated_user.profile_summary
    }.compact_blank
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
      image: @organization.profile_image_url_for(length: 320),
      name: @organization.name,
      description: @organization.summary.presence || I18n.t("stories_controller.404_bio_not_found")
    }
  end

  def user_same_as
    # For further information on the sameAs property, please refer to this link:
    # https://schema.org/sameAs
    [
      @user.twitter_username.present? ? "https://twitter.com/#{@user.twitter_username}" : nil,
      @user.github_username.present? ? "https://github.com/#{@user.github_username}" : nil,
      @user&.profile&.website_url,
    ].compact_blank
  end

  def fetch_sort_order
    return params[:comments_sort] if Comment::VALID_SORT_OPTIONS.include? params[:comments_sort]

    "top"
  end
end
