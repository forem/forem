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
      notice = "Your profile was successfully updated."
      follow_hiring_tag(@user)
      redirect_to "/settings/#{@tab}", notice: notice
    else
      render :edit
    end
  end

  def onboarding_update
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
    if @organization = Organization.find_by_secret(params[:org_secret])
      current_user.update(organization_id: @organization.id)
      redirect_to "/settings/organization",
        notice: "You have joined the #{@organization.name} organization."
    else
      not_found
    end
  end

  def leave_org
    authorize User
    current_user.update(organization_id: nil, org_admin: nil)
    redirect_to "/settings/organization",
      notice: "You have left your organization."
  end

  def add_org_admin
    user = User.find(session[:user_id])
    authorize user
    user.update(org_admin: true)
    user.add_role :analytics_beta_tester if user.organization.approved
    redirect_to "/settings/organization",
      notice: "#{user.name} is now an admin."
  end

  def remove_org_admin
    user = User.find(session[:user_id])
    authorize user
    user.update(org_admin: false)
    redirect_to "/settings/organization",
      notice: "#{user.name} is no longer an admin."
  end

  def remove_from_org
    user = User.find(session[:user_id])
    authorize user
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
      @customer = Stripe::Customer.retrieve(current_user.stripe_id_code) if current_user.stripe_id_code
    when "membership"
      if current_user.monthly_dues.zero?
        redirect_to "/membership"
        return
      end
    end
  end
end
