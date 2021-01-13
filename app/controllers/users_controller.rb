class UsersController < ApplicationController
  before_action :set_no_cache_header
  before_action :raise_suspended, only: %i[update]
  before_action :set_user, only: %i[update confirm_destroy request_destroy full_delete remove_identity]
  after_action :verify_authorized, except: %i[index signout_confirm add_org_admin remove_org_admin remove_from_org]
  before_action :authenticate_user!, only: %i[onboarding_update onboarding_checkbox_update]
  before_action :set_suggested_users, only: %i[index]
  before_action :initialize_stripe, only: %i[edit]

  ALLOWED_USER_PARAMS = %i[last_onboarding_page].freeze
  INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[id name username summary profile_image].freeze
  private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

  def index
    @users =
      case params[:state]
      when "follow_suggestions"
        determine_follow_suggestions(current_user)
      when "sidebar_suggestions"
        Suggester::Users::Sidebar.new(current_user, params[:tag]).suggest.sample(3)
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
    set_current_tab(params["tab"] || "profile")
    handle_settings_tab
  end

  # PATCH/PUT /users/:id.:format
  def update
    set_current_tab(params["user"]["tab"])

    # preferred_languages is handled manually
    @user.language_settings["preferred_languages"] = Languages::LIST.keys & params[:user][:preferred_languages].to_a

    @user.attributes = permitted_attributes(@user)

    if @user.save
      # NOTE: [@rhymes] this queues a job to fetch the feed each time the profile is updated, regardless if the user
      # explicitly requested "Feed fetch now" or simply updated any other field
      import_articles_from_feed(@user)

      notice = "Your profile was successfully updated."
      if config_changed?
        notice = "Your config has been updated. Refresh to see all changes."
      end
      if @user.export_requested?
        notice += " The export will be emailed to you shortly."
        ExportContentWorker.perform_async(@user.id, @user.email)
      end
      cookies.permanent[:user_experience_level] = @user.experience_level.to_s if @user.experience_level.present?
      flash[:settings_notice] = notice
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}"
    else
      Honeycomb.add_field("error", @user.errors.messages.reject { |_, v| v.empty? })
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
      notice = "You have already requested account deletion. Please, check your email for further instructions."
      flash[:settings_notice] = notice
      redirect_to user_settings_path(@tab)
    elsif @user.email?
      Users::RequestDestroy.call(@user)
      notice = "You have requested account deletion. Please, check your email for further instructions."
      flash[:settings_notice] = notice
      redirect_to user_settings_path(@tab)
    else
      flash[:settings_notice] = "Please, provide an email to delete your account."
      redirect_to user_settings_path("account")
    end
  end

  def confirm_destroy
    destroy_token = Rails.cache.read("user-destroy-token-#{@user.id}")
    raise ActionController::RoutingError, "Not Found" unless destroy_token.present? && destroy_token == params[:token]

    set_current_tab("account")
  end

  def full_delete
    set_current_tab("account")
    if @user.email?
      Users::DeleteWorker.perform_async(@user.id)
      sign_out @user
      flash[:global_notice] = "Your account deletion is scheduled. You'll be notified when it's deleted."
      redirect_to root_path
    else
      flash[:settings_notice] = "Please, provide an email to delete your account"
      redirect_to user_settings_path("account")
    end
  end

  def remove_identity
    set_current_tab("account")

    error_message = "An error occurred. Please try again or send an email to: #{SiteConfig.email_addresses[:contact]}"
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

      flash[:settings_notice] = "Your #{provider.official_name} account was successfully removed."
    else
      flash[:error] = error_message
    end

    redirect_to user_settings_path(@tab)
  end

  def onboarding_update
    if params[:user]
      sanitize_user_params
      current_user.assign_attributes(params[:user].permit(ALLOWED_USER_PARAMS))
      current_user.profile_updated_at = Time.current
    end

    if current_user.save && params[:profile]
      update_result = Profiles::Update.call(current_user, { profile: profile_params })
    end

    current_user.saw_onboarding = true
    authorize User
    render_update_response(update_result&.success?)
  end

  def onboarding_checkbox_update
    # TODO: mstruve will remove once debugging is done
    Rails.logger.error("onboarding_checkbox_update_params:#{params}")
    Rails.logger.error("onboarding_checkbox_update_user_params:#{params[:user]}")

    if params[:user]
      permitted_params = %i[
        checked_code_of_conduct checked_terms_and_conditions email_newsletter email_digest_periodic
      ]
      current_user.assign_attributes(params[:user].permit(permitted_params))
    end

    current_user.saw_onboarding = true
    authorize User
    render_update_response(current_user.save)
  end

  def join_org
    authorize User
    if (@organization = Organization.find_by(secret: params[:org_secret].strip))
      OrganizationMembership.create(user_id: current_user.id, organization_id: @organization.id, type_of_user: "member")
      flash[:settings_notice] = "You have joined the #{@organization.name} organization."
      redirect_to "/settings/organization/#{@organization.id}"
    else
      flash[:error] = "The given organization secret was invalid."
      redirect_to "/settings/organization/new"
    end
  end

  def leave_org
    org = Organization.find_by(id: params[:organization_id])
    authorize org
    OrganizationMembership.find_by(organization_id: org.id, user_id: current_user.id)&.delete
    flash[:settings_notice] = "You have left your organization."
    redirect_to "/settings/organization/new"
  end

  def add_org_admin
    adminable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])

    not_authorized unless current_user.org_admin?(org) && OrganizationMembership.exists?(user: adminable,
                                                                                         organization: org)

    OrganizationMembership.find_by(user_id: adminable.id, organization_id: org.id).update(type_of_user: "admin")
    flash[:settings_notice] = "#{adminable.name} is now an admin."
    redirect_to "/settings/organization/#{org.id}"
  end

  def remove_org_admin
    unadminable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])

    not_authorized unless current_user.org_admin?(org) && unadminable.org_admin?(org)

    OrganizationMembership.find_by(user_id: unadminable.id, organization_id: org.id).update(type_of_user: "member")
    flash[:settings_notice] = "#{unadminable.name} is no longer an admin."
    redirect_to "/settings/organization/#{org.id}"
  end

  def remove_from_org
    removable = User.find(params[:user_id])
    org = Organization.find_by(id: params[:organization_id])
    removable_org_membership = OrganizationMembership.find_by(user_id: removable.id, organization_id: org.id)

    not_authorized unless current_user.org_admin?(org) && removable_org_membership

    removable_org_membership.delete
    flash[:settings_notice] = "#{removable.name} is no longer part of your organization."
    redirect_to "/settings/organization/#{org.id}"
  end

  def signout_confirm; end

  def handle_settings_tab
    return @tab = "profile" if @tab.blank?

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

  private

  def sanitize_user_params
    params[:user].delete_if { |_k, v| v.blank? }
  end

  def set_suggested_users
    @suggested_users = SiteConfig.suggested_users
  end

  def default_suggested_users
    @default_suggested_users ||= User.where(username: @suggested_users)
  end

  def determine_follow_suggestions(current_user)
    return default_suggested_users if SiteConfig.prefer_manual_suggested_users? && default_suggested_users

    recent_suggestions = Suggester::Users::Recent.new(
      current_user,
      attributes_to_select: INDEX_ATTRIBUTES_FOR_SERIALIZATION,
    ).suggest

    recent_suggestions.presence || default_suggested_users
  end

  def render_update_response(success)
    outcome = success ? "updated successfully" : "update failed"

    respond_to do |format|
      format.json { render json: { outcome: outcome } }
    end
  end

  def handle_organization_tab
    @organizations = @current_user.organizations.order(name: :asc)
    if params[:org_id] == "new" || params[:org_id].blank? && @organizations.size.zero?
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
    @response_templates = current_user.response_templates
    @response_template = ResponseTemplate.find_or_initialize_by(id: params[:id], user: current_user)
  end

  def set_user
    @user = current_user
    not_found unless @user
    authorize @user
  end

  def set_current_tab(current_tab = "profile")
    @tab = current_tab
  end

  def config_changed?
    params[:user].include?(:config_theme)
  end

  def destroy_request_in_progress?
    Rails.cache.exist?("user-destroy-token-#{@user.id}")
  end

  def import_articles_from_feed(user)
    return if user.feed_url.blank?

    Feeds::ImportArticlesWorker.perform_async(nil, user.id)
  end

  def profile_params
    params[:profile].permit(Profile.attributes)
  end
end
