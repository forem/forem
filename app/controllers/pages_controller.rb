class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[show badge bounty faq robots llms openapi]

  def show
    params[:slug] = combined_fragmented_slug if params[:slug_0].present?
    @page = proper_page_by_slug
    redirect_page_if_different_subforem
    return if performed?

    not_found_conditions

    if @page.redirect_to_url.present?
      redirect_options = { status: :moved_permanently }
      redirect_options[:allow_other_host] = true if @page.redirect_to_url.start_with?("http://", "https://")
      redirect_to @page.redirect_to_url, **redirect_options
      return
    end

    set_surrogate_key_header "show-page-#{params[:slug]}"


    case @page.template
    when "txt"
      render plain: @page.processed_html, content_type: "text/plain"
    when "json"
      render json: @page.body_json
    when "css"
      render plain: @page.body_css, content_type: "text/css"
    end
  end

  def about
    @page = Page.from_subforem.find_by(slug: "about")
    render :show if @page
    set_surrogate_key_header "about_page"
  end

  def about_listings
    @page = Page.find_by(slug: "about-listings")
    render :show if @page
    set_surrogate_key_header "about_listings_page"
  end

  def badge
    render layout: false
    set_surrogate_key_header "badge_page"
  end

  def bounty
    @page = Page.find_by(slug: "security")
    render :show if @page
    set_surrogate_key_header "bounty_page"
  end

  def code_of_conduct
    @page = Page.find_by(slug: "code-of-conduct")
    render :show if @page
    set_surrogate_key_header "code_of_conduct_page"
  end

  def community_moderation
    @page = Page.find_by(slug: "community-moderation")
    render :show if @page
    set_surrogate_key_header "community_moderation_page"
  end

  def contact
    @page = Page.find_by(slug: "contact")
    render :show if @page
    set_surrogate_key_header "contact"
  end

  def faq
    @page = Page.find_by(slug: "faq")
    render :show if @page
    set_surrogate_key_header "faq_page"
  end

  def post_a_job
    @page = Page.find_by(slug: "post-a-job")
    render :show if @page
    set_surrogate_key_header "post_a_job_page"
  end

  def privacy
    @page = Page.find_by(slug: "privacy")
    render :show if @page
    set_surrogate_key_header "privacy_page"
  end

  def tag_moderation
    @page = Page.find_by(slug: "tag-moderation")
    render :show if @page
    set_surrogate_key_header "tag_moderation_page"
  end

  def terms
    @page = Page.find_by(slug: "terms")
    render :show if @page
    set_surrogate_key_header "terms_page"
  end

  def report_abuse
    reported_url =
      valid_utf8_string(params[:reported_url]) ||
      valid_utf8_string(params[:url]) ||
      valid_utf8_string(request.referer)
    @feedback_message = FeedbackMessage.new(
      reported_url: billboard_abuse_url || reported_url&.chomp("?i=i"),
    )
    render "pages/report_abuse"
  end

  def robots
    # dynamically-generated static page
    custom_domain_org
    respond_to :text
    set_surrogate_key_header "robots_page"
  end

  def llms
    # Machine-readable guidance for AI agents and other automated clients.
    # Served at /llms.txt, mirroring the robots.txt convention.
    custom_domain_org
    respond_to :text
    set_surrogate_key_header "llms_page"
  end

  def openapi
    # The generated OpenAPI description of the public API. Served over HTTP so that
    # automated clients can discover the contract instead of guessing at it.
    spec = Rails.root.join("swagger/v1/api_v1.json")
    return not_found unless spec.exist?

    set_surrogate_key_header "openapi_spec"
    render plain: spec.read, content_type: "application/json"
  end

  def welcome
    article = Article.cached_admin_published_with("welcome", subforem_id: RequestStore.store[:subforem_id])
    article ||= Article.cached_admin_published_with("welcome")
    redirect_daily_thread_request(article)
  end

  def challenge
    article = Article.cached_admin_published_with("welcome", subforem_id: RequestStore.store[:subforem_id])
    article ||= Article.cached_admin_published_with("welcome")
    redirect_daily_thread_request(Article.cached_admin_published_with("challenge"))
  end

  def checkin
    daily_thread =
      Article
        .published
        .where(user: User.find_by(username: "codenewbiestaff"))
        .order("articles.published_at" => :desc)
        .first

    redirect_daily_thread_request(daily_thread)
  end

  private

  def proper_page_by_slug
    subforem_pages = Page.from_subforem
    # When subforem filtering is off, the scoped lookup is the same query as the fallback,
    # so a missing slug would otherwise hit the database twice before raising.
    return Page.find_by!(slug: params[:slug]) if subforem_pages.where_clause.empty?

    subforem_pages.find_by(slug: params[:slug]) || Page.find_by!(slug: params[:slug])
  end

  def redirect_daily_thread_request(daily_thread)
    if daily_thread
      redirect_to(Addressable::URI.parse(daily_thread.path).path)
    else
      redirect_to(notifications_path)
    end
  end

  def not_found_conditions
    not_found unless FeatureFlag.accessible?(@page.feature_flag_name, current_user)
    not_found if params[:format] == "txt" && @page.template != "txt"
  end

  def combined_fragmented_slug
    (0..5).filter_map { |i| params["slug_#{i}"] }.join("/")
  end

  def billboard_abuse_url
    billboard_id = valid_utf8_string(params[:billboard])
    admin_billboard_path(billboard_id) if billboard_id
  rescue ActionController::UrlGenerationError
    nil
  end

  def valid_utf8_string(value)
    return unless value.is_a?(String)

    utf8 = value.encoding == Encoding::UTF_8 ? value : value.dup.force_encoding(Encoding::UTF_8)
    return unless utf8.valid_encoding?

    utf8.presence
  end
end
