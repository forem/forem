class UsersController < ApplicationController
  before_action :set_no_cache_header
  after_action :verify_authorized, except: %i[signout_confirm add_org_admin remove_org_admin remove_from_org]

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
    set_user
    set_tabs(params["user"]["tab"])
    if @user.update(permitted_attributes(@user))
      RssReaderFetchUserJob.perform_later(@user.id)
      notice = "Your profile was successfully updated."
      if @user.export_requested?
        notice += " The export will be emailed to you shortly."
        ExportContentJob.perform_later(@user.id)
      end
      cookies.permanent[:user_experience_level] = @user.experience_level.to_s if @user.experience_level.present?
      follow_hiring_tag(@user)
      flash[:settings_notice] = notice
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}"
    else
      render :edit
    end
  end

  def update_twitch_username
    set_user
    set_tabs("integrations")
    new_twitch_username = params[:user][:twitch_username]
    if @user.twitch_username != new_twitch_username
      if @user.update(twitch_username: new_twitch_username)
        @user.touch(:profile_updated_at)
        Streams::TwitchWebhookRegistrationJob.perform_later(@user.id) if @user.twitch_username?
      end
      flash[:settings_notice] = "Your Twitch username was successfully updated."
    end
    redirect_to "/settings/#{@tab}"
  end

  def update_language_settings
    set_user
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

  def destroy
    set_user
    set_tabs("account")
    if @user.articles_count.zero? && @user.comments_count.zero?
      @user.destroy!
      NotifyMailer.account_deleted_email(@user).deliver
      flash[:settings_notice] = "Your account has been deleted."
      sign_out @user
      redirect_to root_path
    else
      flash[:error] = "An error occurred. Try requesting an account deletion below."
      redirect_to "/settings/#{@tab}"
    end
  end

  def remove_association
    set_user
    provider = params[:provider]
    identity = @user.identities.find_by(provider: provider)
    set_tabs("account")

    if @user.identities.size == 2 && identity
      identity.destroy

      identity_username = "#{provider}_username".to_sym
      @user.update(identity_username => nil, profile_updated_at: Time.current)

      flash[:settings_notice] = "Your #{provider.capitalize} account was successfully removed."
    else
      flash[:error] = "An error occurred. Please try again or send an email to: yo@dev.to"
    end
    redirect_to "/settings/#{@tab}"
  end

  def onboarding_update
    current_user.assign_attributes(params[:user].permit(:summary, :location, :employment_title, :employer_name, :last_onboarding_page)) if params[:user]
    current_user.saw_onboarding = true
    authorize User
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

  def onboarding_checkbox_update
    current_user.assign_attributes(params[:user].permit(:checked_code_of_conduct, :checked_terms_and_conditions, :email_membership_newsletter, :email_digest_periodic)) if params[:user]
    current_user.saw_onboarding = true
    authorize User
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

    user.delay.follow(Tag.find_by(name: "hiring"))
  end

  def handle_settings_tab
    return @tab = "profile" if @tab.blank?

    case @tab
    when "organization"
      handle_organization_tab
    when "integrations"
      if current_user.identities.where(provider: "github").any?
        @client = Octokit::Client.
          new(access_token: current_user.identities.where(provider: "github").last.token)
      end
    when "billing"
      stripe_code = current_user.stripe_id_code
      return if stripe_code == "special"

      @customer = Stripe::Customer.retrieve(stripe_code) if stripe_code.present?
    when "membership"
      if current_user.monthly_dues.zero?
        redirect_to "/membership"
        return
      end
    when "account"
      @email_body = <<~HEREDOC
        Hello DEV Team,
        %0A
        %0A
        I would like to delete my dev.to account.
        %0A%0A
        You can keep any comments and discussion posts under the Ghost account.
        %0A
        ---OR---
        %0A
        Please delete all my personal information, including comments and discussion posts.
        %0A
        %0A
        Regards,
        %0A
        YOUR-DEV-USERNAME-HERE
      HEREDOC
    else
      not_found unless @tab_list.map { |t| t.downcase.tr(" ", "-") }.include? @tab
    end
  end

  private

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

  def set_user
    @user = current_user
    authorize @user
  end

  def set_tabs(current_tab = "profile")
    @tab_list = @user.settings_tab_list
    @tab = current_tab
  end
end
