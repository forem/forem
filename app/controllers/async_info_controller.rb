class AsyncInfoController < ApplicationController
  include Devise::Controllers::Rememberable
  # No pundit policy. All actions are unrestricted.
  before_action :set_cache_control_headers, only: %i[shell_version]

  def base_data
    flash.discard(:notice)
    unless user_signed_in?
      render json: {
        param: request_forgery_protection_token,
        token: form_authenticity_token
      }
      return
    end
    if remember_user_token.blank?
      current_user.remember_me = true
      current_user.remember_me!
      remember_me(current_user)
    end
    @user = current_user.decorate
    occasionally_update_analytics
    respond_to do |format|
      format.json do
        render json: {
          param: request_forgery_protection_token,
          token: form_authenticity_token,
          user: user_data.to_json
        }
      end
    end
  end

  def shell_version
    set_surrogate_key_header "shell-version-endpoint"
    # shell_version will change on every deploy. *Technically* could be only on changes to assets and shell, but this is more fool-proof.
    shell_version = ApplicationConfig["HEROKU_SLUG_COMMIT"]
    render json: { version: Rails.env.production? ? shell_version : rand(1000) }.to_json
  end

  def user_data
    Rails.cache.fetch(user_cache_key, expires_in: 15.minutes) do
      {
        id: @user.id,
        name: @user.name,
        username: @user.username,
        profile_image_90: ProfileImage.new(@user).get(width: 90),
        followed_tag_names: @user.cached_followed_tag_names,
        followed_tags: @user.cached_followed_tags.to_json(only: %i[id name bg_color_hex text_color_hex hotness_score], methods: [:points]),
        followed_user_ids: @user.cached_following_users_ids,
        followed_organization_ids: @user.cached_following_organizations_ids,
        followed_podcast_ids: @user.cached_following_podcasts_ids,
        reading_list_ids: ReadingList.new(@user).cached_ids_of_articles,
        blocked_user_ids: @user.all_blocking.pluck(:blocked_id),
        saw_onboarding: @user.saw_onboarding,
        checked_code_of_conduct: @user.checked_code_of_conduct,
        checked_terms_and_conditions: @user.checked_terms_and_conditions,
        number_of_comments: @user.comments.count,
        display_sponsors: @user.display_sponsors,
        trusted: @user.trusted,
        moderator_for_tags: @user.moderator_for_tags,
        experience_level: @user.experience_level,
        preferred_languages_array: @user.preferred_languages_array,
        config_body_class: @user.config_body_class,
        onboarding_variant_version: @user.onboarding_variant_version,
        pro: @user.pro?
      }
    end
  end

  def user_cache_key
    "user-info-#{current_user&.id}__
    #{current_user&.last_sign_in_at}__
    #{current_user&.last_followed_at}__
    #{current_user&.updated_at}__
    #{current_user&.reactions_count}__
    #{current_user&.comments_count}__
    #{current_user&.saw_onboarding}__
    #{current_user&.checked_code_of_conduct}__
    #{current_user&.articles_count}__
    #{current_user&.pro?}__
    #{current_user&.blocking_others_count}__
    #{remember_user_token}"
  end

  def remember_user_token
    cookies[:remember_user_token]
  end

  private

  def occasionally_update_analytics
    return unless Rails.env.production? && rand(SiteConfig.ga_fetch_rate) == 1

    Articles::UpdateAnalyticsWorker.perform_async(@user.id)
  end
end
