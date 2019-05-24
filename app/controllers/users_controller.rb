class UsersController < ApplicationController
  before_action :set_no_cache_header
  after_action :verify_authorized, except: [:signout_confirm]

  # GET /settings/@tab
  def edit
    unless current_user
      skip_authorization
      return redirect_to "/enter"
    end
    @user = current_user
    @tab_list = @user.settings_tab_list
    @tab = params["tab"]

    authorize @user
    handle_settings_tab
  end

  # PATCH/PUT /users/:id.:format
  def update
    @user = current_user
    @tab_list = @user.settings_tab_list
    @tab = params["user"]["tab"] || "profile"
    authorize @user
    if @user.update(permitted_attributes(@user))
      RssReader.new.delay.fetch_user(@user) if @user.feed_url.present?
      Streams::TwitchWebhookRegistrationJob.perform_later(@user.id) if @user.twitch_username.present?
      notice = "Your profile was successfully updated."
      if @user.export_requested?
        notice += " The export will be emailed to you shortly."
        ExportContentJob.perform_later(@user.id)
      end
      cookies.permanent[:user_experience_level] = @user.experience_level.to_s if @user.experience_level.present?
      follow_hiring_tag(@user)
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}", notice: notice
    else
      render :edit
    end
  end

  def update_language_settings
    @user = current_user
    @tab_list = @user.settings_tab_list
    @tab = "misc"
    authorize @user
    @user.language_settings["preferred_languages"] = Languages::LIST.keys & params[:user][:preferred_languages].to_a
    if @user.save
      notice = "Your profile was successfully updated."
      @user.touch(:profile_updated_at)
      redirect_to "/settings/#{@tab}", notice: notice
    else
      render :edit
    end
  end

  def destroy
    @user = current_user
    @tab_list = @user.settings_tab_list
    @tab = "account"
    authorize @user
    if @user.articles_count.zero? && @user.comments_count.zero?
      @user.destroy!
      NotifyMailer.account_deleted_email(@user).deliver
      sign_out @user
      redirect_to root_path, notice: "Your account has been deleted."
    else
      flash[:error] = "An error occurred. Try requesting an account deletion below."
      redirect_to "/settings/#{@tab}"
    end
  end

  def remove_association
    @user = current_user
    authorize @user

    provider = params[:provider]
    identity = @user.identities.find_by(provider: provider)
    @tab_list = @user.settings_tab_list
    @tab = "account"

    if @user.identities.size == 2 && identity
      identity.destroy

      identity_username = "#{provider}_username".to_sym
      @user.update(identity_username => nil, profile_updated_at: Time.current)

      redirect_to "/settings/#{@tab}",
                  notice: "Your #{provider.capitalize} account was successfully removed."
    else
      flash[:error] = "An error occurred. Please try again or send an email to: yo@dev.to"
      redirect_to "/settings/#{@tab}"
    end
  end

  def onboarding_update
    current_user.update(params[:user].permit(:summary, :location, :employment_title, :employer_name)) if params[:user]
    current_user.saw_onboarding = true
    authorize User
    if current_user.save!
      respond_to do |format|
        format.json { render json: { outcome: "onboarding closed" } }
      end
    else
      respond_to do |format|
        format.json { render json: { outcome: "onboarding opened" } }
      end
    end
  end

  def join_org
    authorize User
    if (@organization = Organization.find_by(secret: params[:org_secret]))
      ActiveRecord::Base.transaction do
        current_user.update(organization_id: @organization.id)
        OrganizationMembership.create(user_id: current_user.id, organization_id: current_user.organization_id, type_of_user: "member")
      end
      redirect_to "/settings/organization",
                  notice: "You have joined the #{@organization.name} organization."
    else
      not_found
    end
  end

  def leave_org
    authorize User
    type_of_user = current_user.org_admin ? "admin" : "member"
    OrganizationMembership.find_by(organization_id: current_user.organization_id, user_id: current_user.id, type_of_user: type_of_user)&.delete
    current_user.update(organization_id: nil, org_admin: nil)
    redirect_to "/settings/organization",
                notice: "You have left your organization."
  end

  def add_org_admin
    user = User.find(params[:user_id])
    authorize user
    user.update(org_admin: true)
    org_membership = OrganizationMembership.find_or_initialize_by(user_id: user.id, organization_id: user.organization_id)
    org_membership.type_of_user = "admin"
    org_membership.save
    redirect_to "/settings/organization",
                notice: "#{user.name} is now an admin."
  end

  def remove_org_admin
    user = User.find(params[:user_id])
    authorize user
    user.update(org_admin: false)
    org_membership = OrganizationMembership.find_or_initialize_by(user_id: user.id, organization_id: user.organization_id)
    org_membership.type_of_user = "member"
    org_membership.save
    redirect_to "/settings/organization",
                notice: "#{user.name} is no longer an admin."
  end

  def remove_from_org
    user = User.find(params[:user_id])
    authorize user
    type_of_user = user.org_admin ? "admin" : "member"
    OrganizationMembership.find_by(organization_id: current_user.organization_id, user_id: current_user.id, type_of_user: type_of_user)&.delete
    user.update(organization_id: nil)
    redirect_to "/settings/organization",
                notice: "#{user.name} is no longer part of your organization."
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
      @organization = @user.organization || Organization.new
    when "switch-organizations"
      @organization = Organization.new
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
end
