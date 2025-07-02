class OnboardingsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_suspended, only: %i[notifications]
  before_action :set_cache_control_headers, only: %i[show tags]
  before_action :set_no_cache_header, only: %i[update users_and_organizations]
  after_action :verify_authorized, only: %i[update checkbox]

  SUGGESTED_USER_ATTRIBUTES = %i[id name username summary profile_image].freeze
  TAG_ONBOARDING_ATTRIBUTES = %i[id name taggings_count].freeze
  ALLOWED_USER_PARAMS = %i[last_onboarding_page username name summary profile_image].freeze
  ALLOWED_CHECKBOX_PARAMS = %i[checked_code_of_conduct checked_terms_and_conditions].freeze
  ALLOWED_NOTIFICATION_PARAMS = %i[email_newsletter email_digest_periodic].freeze

  def show
    set_surrogate_key_header "onboarding-slideshow"
  end

  def users_and_organizations
    suggested_follows = suggested_user_follows + suggested_organization_follows
    @suggestions = ApplicationDecorator.decorate_collection(suggested_follows)
  end

  def tags
    @tags = Tags::SuggestedForOnboarding.call
      .select(TAG_ONBOARDING_ATTRIBUTES)

    render json: @tags
    set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
  end

  def update
    authorize User, :onboarding_update?

    user_params = {}

    if params[:user]
      if unset_username?
        return render json: { errors: I18n.t("users_controller.username_blank") }, status: :unprocessable_entity
      end

      sanitize_user_params
      user_params = params[:user].permit(ALLOWED_USER_PARAMS)
    end

    update_result = Users::Update.call(current_user, user: user_params, profile: profile_params)

    if update_result.success?
      render json: {}, status: :ok
    else
      render json: { errors: update_result.errors_as_sentence }, status: :unprocessable_entity
    end
  end

  def checkbox
    authorize User, :onboarding_checkbox_update?

    if params[:user]
      current_user.assign_attributes(params[:user].permit(ALLOWED_CHECKBOX_PARAMS))
    end

    current_user.saw_onboarding = true

    if current_user.save
      render json: {}, status: :ok
    else
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end

  def notifications
    authorize User, :onboarding_notifications_checkbox_update?

    if params[:notifications]
      current_user.notification_setting.assign_attributes(params[:notifications].permit(ALLOWED_NOTIFICATION_PARAMS))
    end

    current_user.saw_onboarding = true

    success = current_user.notification_setting.save
    notifications_updated_response(success, current_user.notification_setting.errors_as_sentence)
  end

  def newsletter
    respond_to do |format|
      format.json do
        rendered_content = render_to_string(partial: "onboardings/newsletter",
                                            formats: [:html],
                                            layout: false)
        render json: { content: rendered_content }
      end
    end
  end

  private

  def unset_username?
    params[:user].key?(:username) && params[:user][:username].blank?
  end

  def sanitize_user_params
    params[:user].compact_blank!
  end

  def profile_params
    params[:profile]&.permit(Profile.static_fields + Profile.attributes)
  end

  def notifications_updated_response(success, errors)
    status = success ? 200 : 422

    respond_to do |format|
      format.json { render json: { errors: errors }, status: status }
    end
  end

  def suggested_organization_follows
    Organizations::SuggestProminent.call(current_user)
  end

  def suggested_user_follows
    Users::SuggestProminent.call(current_user,
                                 attributes_to_select: SUGGESTED_USER_ATTRIBUTES)
  end
end
