class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: %i[show rlyweb now survey badge shecoded bounty faq]

  def show
    @page = Page.find_by!(slug: params[:slug])
    set_surrogate_key_header "show-page-#{params[:slug]}"
  end

  def now
    set_surrogate_key_header "now_page"
  end

  def survey
    set_surrogate_key_header "survey_page"
  end

  def about
    @page = Page.find_by(slug: "about")
    render :show if @page
    set_surrogate_key_header "about_page"
  end

  def faq
    @page = Page.find_by(slug: "faq")
    render :show if @page
    set_surrogate_key_header "faq_page"
  end

  def bounty
    @page = Page.find_by(slug: "security")
    render :show if @page
    set_surrogate_key_header "bounty_page"
  end

  def badge
    @html_variant = HtmlVariant.find_for_test([], "badge_landing_page")
    render layout: false
    set_surrogate_key_header "badge_page"
  end

  def onboarding
    set_surrogate_key_header "onboarding_page"
  end

  def report_abuse
    reported_url = params[:reported_url] || params[:url] || request.referer
    @feedback_message = FeedbackMessage.new(
      reported_url: reported_url&.chomp("?i=i"),
    )
    render "pages/report-abuse"
  end

  def rlyweb
    set_surrogate_key_header "rlyweb"
  end

  def welcome
    daily_thread = latest_published_thread("welcome")
    if daily_thread
      redirect_to daily_thread.path
    else
      # fail safe if we haven't made the first welcome thread
      redirect_to "/notifications"
    end
  end

  def challenge
    daily_thread = latest_published_thread("challenge")
    if daily_thread
      redirect_to daily_thread.path
    else
      redirect_to "/notifications"
    end
  end

  def live
    @active_channel = ChatChannel.find_by(channel_name: "Workshop")
    @chat_channels = [@active_channel].to_json(
      only: %i[channel_name channel_type last_message_at slug status id],
    )
  end

  def shecoded
    @top_articles = Article.published.tagged_with(%w[shecoded shecodedally theycoded], any: true).
      where(approved: true).where("published_at > ? AND score > ?", 3.weeks.ago, 28).
      order(Arel.sql("RANDOM()")).
      includes(:user).decorate
    @articles = Article.published.tagged_with(%w[shecoded shecodedally theycoded], any: true).
      where(approved: true).where("published_at > ? AND score > ?", 3.weeks.ago, -8).
      order(Arel.sql("RANDOM()")).
      where.not(id: @top_articles).
      includes(:user).decorate
    render layout: false
    set_surrogate_key_header "shecoded_page"
  end

  private

  def latest_published_thread(tag_name)
    Article.published.
      where(user_id: ApplicationConfig["DEVTO_USER_ID"]).
      order("published_at ASC").
      tagged_with(tag_name).last
  end
end
