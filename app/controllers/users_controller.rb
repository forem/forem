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
    # raise permitted_attributes(@user).to_s
    if @user.update(permitted_attributes(@user))
      RssReader.new(request.request_id).delay.fetch_user(@user) if @user.feed_url.present?
      notice = "Your profile was successfully updated."

      if @user.export_requested?
        notice = notice + " The export will be emailed to you shortly."
        Exporter::Service.new(@user).delay.export(send_email: true)
      end

      follow_hiring_tag(@user)
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
    if @user.identities.count == 2 && identity
      identity.destroy
      identity_username = "#{provider}_username".to_sym
      @user.update(identity_username => nil)
      redirect_to "/settings/#{@tab}",
        notice: "Your #{provider.capitalize} account was successfully removed."
    else
      flash[:error] = "An error occurred. Please try again or send an email to: yo@dev.to"
      redirect_to "/settings/#{@tab}"
    end
  end

  def onboarding_update
    if params[:user]
      current_user.update(JSON.parse(params[:user]).to_h)
    end
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
      stripe_code = current_user.stripe_id_code
      return if stripe_code == "special"
      @customer = Stripe::Customer.retrieve(stripe_code) if !stripe_code.blank?
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
      not_found unless @tab_list.map { |t| t.downcase.gsub(" ", "-") }.include? @tab
    end
  end
end
