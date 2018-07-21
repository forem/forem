class PagesController < ApplicationController
  # No authorization required for entirely public controller
  before_action :set_cache_control_headers, only: [:rlyweb, :now, :events, :membership, :survey]

  def now
    set_surrogate_key_header "now_page"
  end

  def survey
    set_surrogate_key_header "survey_page"
  end

  def about
    set_surrogate_key_header "about_page"
  end

  def membership
    flash[:notice] = ""
    flash[:error] = ""
    @members = members_for_display
    set_surrogate_key_header "membership_page"
  end

  def membership_form
    render "membership_form", layout: false
  end

  def report_abuse
    @feedback_message = FeedbackMessage.new(
      reported_url: params[:reported_url] || params[:url] || request.referrer,
    )
    render "pages/report-abuse"
  end

  def rlyweb
    set_surrogate_key_header "rlyweb"
  end

  def welcome
    daily_thread = latest_published_welcome_thread
    if daily_thread
      redirect_to daily_thread.path
    else
      # fail safe if we haven't made the first welcome thread
      redirect_to "/notifications"
    end
  end

  def live
    @active_channel = ChatChannel.find_by_channel_name("Workshop")
    @chat_channels = [@active_channel].to_json(
      only: [:channel_name,:channel_type,:last_message_at,:slug, :status, :id])
  end

  private # helpers

  def latest_published_welcome_thread
    Article.where(user_id: ApplicationConfig["DEVTO_USER_ID"], published: true).
      tagged_with("welcome").last
  end

  def members_for_display
    Rails.cache.fetch("members-for-display-on-membership-page", expires_in: 6.hours) do
      members = User.with_any_role(:level_1_member,
                                  :level_2_member,
                                  :level_3_member,
                                  :level_4_member,
                                  :triple_unicorn_member,
                                  :workshop_pass)
      team_ids = [1, 264, 6, 3, 31047, 510, 560, 1075, 48943, 13962]
      members.reject { |user| team_ids.include?(user.id) }.shuffle
    end
  end
end
