class AsyncInfoController < ApplicationController
  # No pundit policy. All actions are unrestricted.
  before_action :set_cache_control_headers, only: %i[shell_version]

  def base_data
    flash.discard(:notice)
    unless user_signed_in?
      render json: {
        broadcast: broadcast_data,
        param: request_forgery_protection_token,
        token: form_authenticity_token
      }
      return
    end
    @user = current_user.decorate
    respond_to do |format|
      format.json do
        render json: {
          broadcast: broadcast_data,
          param: request_forgery_protection_token,
          token: form_authenticity_token,
          user: user_data
        }
      end
    end
  end

  # TODO: Remove these "shell_version", because they are for service worker functionality we no longer need.
  # We are keeping these around mid-March 2021 because previously-installed service workers may still expect them.
  def shell_version
    set_surrogate_key_header "shell-version-endpoint"
    # shell_version will change on every deploy.
    # *Technically* could be only on changes to assets and shell, but this is more fool-proof.
    shell_version = ForemInstance.deployed_at.to_s + SiteConfig.admin_action_taken_at.to_s
    render json: { version: shell_version }.to_json
  end

  def broadcast_data
    broadcast = Broadcast.announcement.active.first.presence
    return unless broadcast

    {
      title: broadcast&.title,
      html: broadcast&.processed_html,
      banner_class: helpers.banner_class(broadcast)
    }.to_json
  end

  def user_data
    Rails.cache.fetch(user_cache_key, expires_in: 15.minutes) do
      {
        id: @user.id,
        name: @user.name,
        username: @user.username,
        profile_image_90: Images::Profile.call(@user.profile_image_url, length: 90),
        followed_tags: @user.cached_followed_tags.to_json(only: %i[id name bg_color_hex text_color_hex hotness_score],
                                                          methods: [:points]),
        followed_podcast_ids: @user.cached_following_podcasts_ids,
        reading_list_ids: @user.cached_reading_list_article_ids,
        blocked_user_ids: UserBlock.cached_blocked_ids_for_blocker(@user.id),
        saw_onboarding: @user.saw_onboarding,
        checked_code_of_conduct: @user.checked_code_of_conduct,
        checked_terms_and_conditions: @user.checked_terms_and_conditions,
        display_sponsors: @user.display_sponsors,
        display_announcements: @user.display_announcements,
        trusted: @user.trusted,
        moderator_for_tags: @user.moderator_for_tags,
        config_body_class: @user.config_body_class,
        pro: @user.pro?,
        feed_style: feed_style_preference,
        created_at: @user.created_at,
        admin: @user.any_admin?
      }
    end.to_json
  end

  def user_cache_key
    "user-info-#{current_user&.id}__
    #{current_user&.last_sign_in_at}__
    #{current_user&.following_tags_count}__
    #{current_user&.last_followed_at}__
    #{current_user&.last_reacted_at}__
    #{current_user&.updated_at}__
    #{current_user&.reactions_count}__
    #{current_user&.articles_count}__
    #{current_user&.pro?}__
    #{current_user&.blocking_others_count}__"
  end
end
