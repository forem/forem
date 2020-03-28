class UsersController < ApplicationController
  before_action :set_no_cache_header
  before_action :raise_suspended, only: %i[update]
  before_action :set_user, only: %i[update update_twitch_username update_language_settings confirm_destroy request_destroy full_delete remove_association]
  after_action :verify_authorized, except: %i[index signout_confirm add_org_admin remove_org_admin remove_from_org]
  before_action :authenticate_user!, only: %i[onboarding_update onboarding_checkbox_update]

  DEFAULT_FOLLOW_SUGGESTIONS = %w[ben jess peter maestromac andy liana].freeze

  def index
    if !user_signed_in? || less_than_one_day_old?(current_user)
      @users = User.where(username: DEFAULT_FOLLOW_SUGGESTIONS)
      return
    end

    @users =
      if params[:state] == "follow_suggestions"
        Suggester::Users::Recent.new(
          current_user,
          attributes_to_select: INDEX_ATTRIBUTES_FOR_SERIALIZATION,
        ).suggest
      elsif params[:state] == "sidebar_suggestions"
        Suggester::Users::Sidebar.new(current_user, params[:tag]).suggest.sample(3)
      else
        User.none
      end
  end

  INDEX_ATTRIBUTES_FOR_SERIALIZATION = %i[id name username summary profile_image].freeze
  private_constant :INDEX_ATTRIBUTES_FOR_SERIALIZATION

  # GET /settings/@tab
  def edit
    unless current_user
      skip_authorization
      return redirect_to sign_up_path
    end
    set_user
    set_tabs(params["tab"] || "profile")
    handle_settings_tab
  end

  # PATCH/PUT /users/:id.:format
  def update
    set_tabs(params["user"]["tab"])
    if @user.update(permitted_attributes(@user))
      RssReaderFetchUserWorker.perform_async(@user.id) if @user.feed_url.present?
      notice = "Your profile was successfully updated."
      if config_changed?
        notice = "Your config has been updated. Refresh to see all changes."
      end
      if @user.export_requested?
        notice += " The export will be emailed to you shortly."
        ExportContentWorker.perform_async(@user.id)
      end
      cookies.permanent[:user_experience_level] = @user.experience_level.to_s if @user.experience_level.present?
      follow_hiring_tag(@user)
      flash[:settings_notice] = notice
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}"
    else
      Honeycomb.add_field("error",
                          @user.errors.messages.reject { |_, v| v.empty? })
      Honeycomb.add_field("errored", true)
      render :edit, status: :bad_request
    end
  end

  def update_twitch_username
    set_tabs("integrations")
    new_twitch_username = params[:user][:twitch_username]
    if @user.twitch_username != new_twitch_username
      if @user.update(twitch_username: new_twitch_username)
        @user.touch(:profile_updated_at)
        Streams::TwitchWebhookRegistrationWorker.perform_async(@user.id) if @user.twitch_username?
      end
      flash[:settings_notice] = "Your Twitch username was successfully updated."
    end
    redirect_to "/settings/#{@tab}"
  end

  def update_language_settings
    set_tabs("misc")
    @user.language_settings["preferred_languages"] = Languages::LIST.keys & params[:user][:preferred_languages].to_a
    if @user.save
      flash[:settings_notice] = "Your language settings were successfully updated."
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}"
    else
      render :edit
    end
  end

  def request_destroy
    set_tabs("account")
    if @user.email?
      Users::RequestDestroy.call(@user)
      flash[:settings_notice] = "You have requested account deletion. Please, check your email for further instructions."
      redirect_to "/settings/#{@tab}"
    else
      flash[:settings_notice] = "Please, provide an email to delete your account."
      redirect_to "/settings/account"
    end
  end

  def confirm_destroy
    destroy_token = Rails.cache.read("user-destroy-token-#{@user.id}")
    raise ActionController::RoutingError, "Not Found" unless destroy_token.present? && destroy_token == params[:token]

    set_tabs("account")
  end

  def full_delete
    set_tabs("account")
    if @user.email?
      Users::DeleteWorker.perform_async(@user.id)
      sign_out @user
      flash[:global_notice] = "Your account deletion is scheduled. You'll be notified when it's deleted."
      redirect_to root_path
    else
      flash[:settings_notice] = "Please, provide an email to delete your account"
      redirect_to "/settings/account"
    end
  end

  def remove_association
    provider = params[:provider]
    identity = @user.identities.find_by(provider: provider)
    set_tabs("account")

    if @user.identities.size == 2 && identity
      identity.destroy

      identity_username = "#{provider}_username".to_sym
      @user.update(identity_username => nil, :profile_updated_at => Time.current)

      flash[:settings_notice] = "Your #{provider.capitalize} account was successfully removed."
    else
      flash[:error] = "An error occurred. Please try again or send an email to: #{SiteConfig.default_site_email}"
    end
    redirect_to "/settings/#{@tab}"
  end

  def onboarding_update
    if params[:user]
      permitted_params = %i[summary location employment_title employer_name last_onboarding_page]
      current_user.assign_attributes(params[:user].permit(permitted_params))
    end
    current_user.saw_onboarding = true
    authorize User
    render_update_response
  end

  def onboarding_checkbox_update
    if params[:user]
      permitted_params = %i[
        checked_code_of_conduct checked_terms_and_conditions email_newsletter email_digest_periodic
      ]
      current_user.assign_attributes(params[:user].permit(permitted_params))
    end

    current_user.saw_onboarding = true
    authorize User
    render_update_response
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

    not_authorized unless current_user.org_admin?(org) && OrganizationMembership.exists?(user: adminable, organization: org)

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

  def follow_hiring_tag(user)
    return unless user.looking_for_work?

    hiring_tag = Tag.find_by(name: "hiring")
    Users::FollowWorker.perform_async(user.id, hiring_tag.id, "Tag")
  end

  def handle_settings_tab
    return @tab = "profile" if @tab.blank?

    case @tab
    when "organization"
      handle_organization_tab
    when "integrations"
      handle_integrations_tab
    when "billing"
      handle_billing_tab
    when "pro-membership"
      handle_pro_membership_tab
    when "account"
      handle_account_tab
    when "response-templates"
      handle_response_templates_tab
    else
      not_found unless @tab_list.map { |t| t.downcase.tr(" ", "-") }.include? @tab
    end
  end

  private

  def render_update_response
    if current_user.save
      respond_to do |format|
        format.json { render json: { outcome: "updated successfully" } }
      end
    else
      respond_to do |format|
        format.json { render json: { outcome: "update failed" } }
      end
    end
  end

  def handle_organization_tab
    @organizations = @current_user.organizations.order("name ASC")
    if params[:org_id] == "new" || params[:org_id].blank? && @organizations.size.zero?
      @organization = Organization.new
    elsif params[:org_id].blank? || params[:org_id].match?(/\d/)
      @organization = Organization.find_by(id: params[:org_id]) || @organizations.first
      authorize @organization, :part_of_org?

      @org_organization_memberships = @organization.organization_memberships.includes(:user)
      @organization_membership = OrganizationMembership.find_by(user_id: current_user.id, organization_id: @organization.id)
    end
  end

  def handle_integrations_tab
    return unless current_user.identities.where(provider: "github").any?

    @client = Octokit::Client.
      new(access_token: current_user.identities.where(provider: "github").last.token)
  end

  def handle_billing_tab
    stripe_code = current_user.stripe_id_code
    return if stripe_code == "special"

    @customer = Payments::Customer.get(stripe_code) if stripe_code.present?
  end

  def handle_pro_membership_tab
    @pro_membership = current_user.pro_membership
  end

  def handle_account_tab
    @email_body = <<~HEREDOC
      Hello #{ApplicationConfig['COMMUNITY_NAME']} Team,
      %0A
      %0A
      I would like to delete my account.
      %0A%0A
      You can keep any comments and discussion posts under the Ghost account.
      %0A
      %0A
      Regards,
      %0A
      YOUR-DEV-USERNAME-HERE
    HEREDOC
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

  def set_tabs(current_tab = "profile")
    @tab_list = @user.settings_tab_list
    @tab = current_tab
  end

  def config_changed?
    params[:user].include?(:config_theme)
  end

  def less_than_one_day_old?(user)
    range = 1.day.ago.beginning_of_day..Time.current
    user_identity_age = user.github_created_at || user.twitter_created_at || 8.days.ago
    # last one is a fallback in case both are nil
    range.cover? user_identity_age
  end
end
