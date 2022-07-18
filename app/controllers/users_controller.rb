class UsersController < ApplicationController
  before_action :set_no_cache_header
  before_action :check_suspended, only: %i[update update_password]
  before_action :set_user,
                only: %i[update update_password request_destroy full_delete remove_identity]
  after_action :verify_authorized,
               except: %i[index signout_confirm add_org_admin remove_org_admin remove_from_org confirm_destroy]
  before_action :set_suggested_users, only: %i[index]
  before_action :initialize_stripe, only: %i[edit]

  INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[id name username summary profile_image].freeze
  private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

  def index
    @users =
      case params[:state]
      when "follow_suggestions"
        determine_follow_suggestions(current_user)
      when "sidebar_suggestions"
        Users::SuggestForSidebar.call(current_user, params[:tag]).sample(3)
      else
        User.none
      end
  end

  # GET /settings/@tab
  def edit
    unless current_user
      skip_authorization
      return redirect_to sign_up_path
    end
    set_user
    set_users_setting_and_notification_setting
    set_current_tab(params["tab"] || "profile")
    handle_settings_tab
  end

  # PATCH/PUT /users/:id.:format
  def update
    set_current_tab(params["user"]["tab"])
    set_users_setting_and_notification_setting

    if @user.update(permitted_attributes(@user))
      # NOTE: [@rhymes] this queues a job to fetch the feed each time the profile is updated, regardless if the user
      # explicitly requested "Feed fetch now" or simply updated any other field
      import_articles_from_feed(@user)

      notice = I18n.t("users_controller.updated_profile")
      if @user.export_requested?
        notice += I18n.t("users_controller.send_export")
        ExportContentWorker.perform_async(@user.id, @user.email)
      end
      if @user.setting.experience_level.present?
        cookies.permanent[:user_experience_level] = @user.setting.experience_level.to_s
      end
      flash[:settings_notice] = notice
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}"
    else
      Honeycomb.add_field("error", @user.errors.messages.compact_blank)
      Honeycomb.add_field("errored", true)

      if @tab
        render :edit, status: :bad_request
      else
        flash[:error] = @user.errors.full_messages.join(", ")
        redirect_to "/settings"
      end
    end
  end

  def request_destroy
    set_current_tab("account")

    if destroy_request_in_progress?
      notice = I18n.t("users_controller.deletion_in_progress")
      flash[:settings_notice] = notice
      redirect_to user_settings_path(@tab)
    elsif @user.email?
      Users::RequestDestroy.call(@user)
      notice = I18n.t("users_controller.deletion_requested")
      flash[:settings_notice] = notice
      redirect_to user_settings_path(@tab)
    else
      flash[:settings_notice] = I18n.t("users_controller.provide_email")
      redirect_to user_settings_path("account")
    end
  end

  def confirm_destroy
    @user = current_user

    if @user
      authorize @user
    else
      flash[:alert] = I18n.t("users_controller.log_in_to_delete")
      redirect_to sign_up_path and return
    end

    destroy_token = Rails.cache.read("user-destroy-token-#{@user.id}")

    if destroy_token.blank?
      flash[:settings_notice] = I18n.t("users_controller.token_expired")
      redirect_to user_settings_path("account")
    elsif destroy_token != params[:token]
      Honeycomb.add_field("destroy_token", destroy_token)
      Honeycomb.add_field("token", params[:token])

      raise ActionController::RoutingError, "Not Found"
    end
  end

  def full_delete
    set_current_tab("account")
    if @user.email?
      Users::DeleteWorker.perform_async(@user.id)
      sign_out @user
      flash[:global_notice] = I18n.t("users_controller.deletion_scheduled")
      redirect_to new_user_registration_path
    else
      flash[:settings_notice] = I18n.t("users_controller.provide_email_delete")
      redirect_to user_settings_path("account")
    end
  end

  def remove_identity
    set_current_tab("account")

    error_message = I18n.t("errors.messages.try_again_email", email: ForemInstance.contact_email)
    unless Authentication::Providers.enabled?(params[:provider])
      flash[:error] = error_message
      redirect_to user_settings_path(@tab)
      return
    end

    provider = Authentication::Providers.get!(params[:provider])

    identity = @user.identities.find_by(provider: provider.provider_name)

    if identity && @user.identities.size > 1
      identity.destroy

      @user.update(
        provider.user_username_field => nil,
        :profile_updated_at => Time.current,
      )

      # GitHub repositories are tied with the existence of the GitHub identity
      # as we use the user's GitHub token to fetch them from the API.
      # We should delete them when a user unlinks their GitHub account.
      @user.github_repos.destroy_all if provider.provider_name == :github

      flash[:settings_notice] =
        I18n.t("users_controller.removed_identity", provider: provider.official_name)
    else
      flash[:error] = error_message
    end

    redirect_to user_settings_path(@tab)
  end

  def join_org
    authorize User
    if (@organization = Organization.find_by(secret: params[:org_secret].strip))
      OrganizationMembership.create(user_id: current_user.id, organization_id: @organization.id, type_of_user: "member")
      flash[:settings_notice] =
        I18n.t("users_controller.joined_org", organization_name: @organization.name)
      redirect_to "/settings/organization/#{@organization.id}"
    else
      flash[:error] = I18n.t("users_controller.invalid_secret")
      redirect_to "/settings/organization/new"
    end
  end

  def leave_org
    org = Organization.find_by(id: params[:organization_id])
    authorize org
    OrganizationMembership.find_by(organization_id: org.id, user_id: current_user.id)&.delete
    flash[:settings_notice] = I18n.t("users_controller.left_org")
    redirect_to "/settings/organization/new"
  end

  def add_org_admin
    adminable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])

    not_authorized unless current_user.org_admin?(org) && OrganizationMembership.exists?(user: adminable,
                                                                                         organization: org)

    OrganizationMembership.find_by(user_id: adminable.id, organization_id: org.id).update(type_of_user: "admin")
    flash[:settings_notice] = I18n.t("users_controller.added_admin", name: adminable.name)
    redirect_to "/settings/organization/#{org.id}"
  end

  def remove_org_admin
    unadminable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])

    not_authorized unless current_user.org_admin?(org) && unadminable.org_admin?(org)

    OrganizationMembership.find_by(user_id: unadminable.id, organization_id: org.id).update(type_of_user: "member")
    flash[:settings_notice] = I18n.t("users_controller.removed_admin", name: unadminable.name)
    redirect_to "/settings/organization/#{org.id}"
  end

  def remove_from_org
    removable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])
    removable_org_membership = OrganizationMembership.find_by(user_id: removable.id, organization_id: org.id)

    not_authorized unless current_user.org_admin?(org) && removable_org_membership

    removable_org_membership.delete
    flash[:settings_notice] = I18n.t("users_controller.removed_member", name: removable.name)
    redirect_to "/settings/organization/#{org.id}"
  end

  def signout_confirm; end

  def handle_settings_tab
    case @tab
    when "profile"
      handle_integrations_tab
    when "organization"
      handle_organization_tab
    when "billing"
      handle_billing_tab
    when "response-templates"
      handle_response_templates_tab
    when "extensions"
      handle_integrations_tab
      handle_response_templates_tab
    else
      not_found unless @tab.in?(Constants::Settings::TAB_LIST.map { |t| t.downcase.tr(" ", "-") })
    end
  end

  def update_password
    set_current_tab("account")

    if @user.update_with_password(password_params)
      redirect_to user_settings_path(@tab)
    else
      Honeycomb.add_field("error", @user.errors.messages.compact_blank)
      Honeycomb.add_field("errored", true)

      if @tab
        render :edit, status: :bad_request
      else
        flash[:error] = @user.errors_as_sentence
        redirect_to user_settings_path
      end
    end
  end

  private

  def set_suggested_users
    @suggested_users = Settings::General.suggested_users
  end

  def default_suggested_users
    @default_suggested_users ||= User.includes(:profile).where(username: @suggested_users)
  end

  def determine_follow_suggestions(current_user)
    return default_suggested_users if Settings::General.prefer_manual_suggested_users? && default_suggested_users

    recent_suggestions = Users::SuggestRecent.call(
      current_user,
      attributes_to_select: INDEX_ATTRIBUTES_FOR_SERIALIZATION,
    )

    recent_suggestions.presence || default_suggested_users
  end

  def handle_organization_tab
    @organizations = @current_user.organizations.order(name: :asc)
    if params[:org_id] == "new" || (params[:org_id].blank? && @organizations.size.zero?)
      @organization = Organization.new
    elsif params[:org_id].blank? || params[:org_id].match?(/\d/)
      @organization = Organization.find_by(id: params[:org_id]) || @organizations.first
      authorize @organization, :part_of_org?

      @org_organization_memberships = @organization.organization_memberships.includes(:user)
      @organization_membership = OrganizationMembership.find_by(user_id: current_user.id,
                                                                organization_id: @organization.id)
    end
  end

  def handle_integrations_tab
    @github_repositories_show = current_user.authenticated_through?(:github)
  end

  def handle_billing_tab
    stripe_code = current_user.stripe_id_code
    return if stripe_code == "special"

    @customer = Payments::Customer.get(stripe_code) if stripe_code.present?
  end

  def handle_response_templates_tab
    @personal_response_templates = current_user.response_templates
    @trusted_response_templates = policy_scope(ResponseTemplate).where(type_of: "mod_comment")
    @response_template = policy_scope(ResponseTemplate).find_by(id: params[:id]) ||
      ResponseTemplate.new
  end

  def set_user
    @user = current_user
    not_found unless @user
    authorize @user
  end

  def set_users_setting_and_notification_setting
    return unless @user

    @users_setting = @user.setting
    @users_notification_setting = @user.notification_setting
  end

  def set_current_tab(current_tab = "profile")
    @tab = current_tab
  end

  def destroy_request_in_progress?
    Rails.cache.exist?("user-destroy-token-#{@user.id}")
  end

  def import_articles_from_feed(user)
    return if user.setting.feed_url.blank?

    Feeds::ImportArticlesWorker.perform_async(user.id)
  end

  def password_params
    params.permit(:current_password, :password, :password_confirmation)
  end
end
