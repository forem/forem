class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[show rlyweb badge bounty faq robots]

  def show
    @page = Page.find_by!(slug: params[:slug])
    set_surrogate_key_header "show-page-#{params[:slug]}"
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

  def bounty
    @page = Page.find_by(slug: "security")
    render :show if @page
    set_surrogate_key_header "bounty_page"
  end

  def community_moderation
    @page = Page.find_by(slug: "community-moderation")
    render :show if @page
    set_surrogate_key_header "community_moderation_page"
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

  def tag_moderation
    @page = Page.find_by(slug: "tag-moderation")
    render :show if @page
    set_surrogate_key_header "tag_moderation_page"
  end

  def badge
    @html_variant = HtmlVariant.find_for_test([], "badge_landing_page")
    render layout: false
    set_surrogate_key_header "badge_page"
  end

  def report_abuse
    referer = URL.sanitized_referer(request.referer)
    reported_url = params[:reported_url] || params[:url] || referer
    @feedback_message = FeedbackMessage.new(
      reported_url: reported_url&.chomp("?i=i"),
    )
    render "pages/report-abuse"
  end

  def robots
    respond_to :text
    set_surrogate_key_header "robots_page"
  end

  def rlyweb
    set_surrogate_key_header "rlyweb"
  end

  def welcome
    daily_thread = Article.admin_published_with("welcome").first
    if daily_thread
      redirect_to daily_thread.path
    else
      # fail safe if we haven't made the first welcome thread
      redirect_to "/notifications"
    end
  end

  def challenge
    daily_thread = Article.admin_published_with("challenge").first
    if daily_thread
      redirect_to daily_thread.path
    else
      redirect_to "/notifications"
    end
  end

  def checkin
    daily_thread =
      Article.
        published.
        where(user: User.find_by(username: "codenewbiestaff")).
        order("articles.published_at" => :desc).
        first

    if daily_thread
      redirect_to daily_thread.path
    else
      redirect_to "/notifications"
    end
  end

  def crayons
    @page = Page.find_by(slug: "crayons")
    render :show if @page
    set_surrogate_key_header "crayons_page"
  end
end
