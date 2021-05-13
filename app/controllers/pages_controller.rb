class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[show badge bounty faq robots]

  def show
    @page = Page.find_by!(slug: params[:slug])
    not_found unless FeatureFlag.accessible?(@page.feature_flag_name, current_user)

    set_surrogate_key_header "show-page-#{params[:slug]}"
    render json: @page.body_json if @page.template == "json"
  end

  def about
    @page = Page.find_by(slug: "about")
    render :show if @page
    set_surrogate_key_header "about_page"
  end

  def about_listings
    @page = Page.find_by(slug: "about-listings")
    render :show if @page
    set_surrogate_key_header "about_listings_page"
  end

  def badge
    @html_variant = HtmlVariant.find_for_test([], "badge_landing_page")
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
    reported_url = params[:reported_url] || params[:url] || request.referer.presence
    @feedback_message = FeedbackMessage.new(
      reported_url: reported_url&.chomp("?i=i"),
    )
    render "pages/report_abuse"
  end

  def robots
    # dynamically-generated static page
    respond_to :text
    set_surrogate_key_header "robots_page"
  end

  def welcome
    redirect_daily_thread_request(Article.admin_published_with("welcome").first)
  end

  def challenge
    redirect_daily_thread_request(Article.admin_published_with("challenge").first)
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

  def redirect_daily_thread_request(daily_thread)
    if daily_thread
      redirect_to(URI.parse(daily_thread.path).path)
    else
      redirect_to(notifications_path)
    end
  end
end
