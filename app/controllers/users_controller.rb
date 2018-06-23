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
    if @user.update(user_params)
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
    user = User.find(params[:user_id])
    authorize user
    user.update(org_admin: true)
    user.add_role :analytics_beta_tester if user.organization.approved
    redirect_to "/settings/organization",
      notice: "#{user.name} is now an admin."
  end

  def remove_org_admin
    user = User.find(params[:user_id])
    authorize user
    user.update(org_admin: false)
    redirect_to "/settings/organization",
      notice: "#{user.name} is no longer an admin."
  end

  def remove_from_org
    user = User.find(params[:user_id])
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

  private

  def user_params
    accessible = %i[name
                    email
                    username
                    profile_image
                    website_url
                    summary
                    email_newsletter
                    email_digest_periodic
                    email_membership_newsletter
                    email_comment_notifications
                    email_mention_notifications
                    email_follower_notifications
                    email_badge_notifications
                    email_unread_notifications
                    bg_color_hex
                    text_color_hex
                    employer_name
                    employer_url
                    employment_title
                    currently_learning
                    available_for
                    mostly_work_with
                    currently_hacking_on
                    location
                    email_public
                    education
                    looking_for_work
                    looking_for_work_publicly
                    contact_consent
                    feed_url
                    feed_mark_canonical
                    prefer_language_en
                    prefer_language_ja
                    prefer_language_es
                    prefer_language_fr
                    prefer_language_it
                    display_sponsors
                    permit_adjacent_sponsors
                    feed_admin_publish_permission]
    accessible << %i[password password_confirmation] unless params[:user][:password].blank?
    params.require(:user).
      permit(accessible).
      transform_values do |value|
        if value.class.name == "String"
          ActionController::Base.helpers.strip_tags(value)
        else
          value
        end
      end
  end
end
