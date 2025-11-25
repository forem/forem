class OrganizationsController < ApplicationController
  skip_before_action :verify_private_forem, only: :confirm_invitation
  after_action :verify_authorized
  skip_after_action :verify_authorized, only: [:members, :confirm_invitation]

  ORGANIZATIONS_PERMITTED_PARAMS = %i[
    id
    name
    summary
    tag_line
    slug
    url
    proof
    profile_image
    location
    company_size
    tech_stack
    email
    story
    bg_color_hex
    text_color_hex
    twitter_username
    github_username
    cta_button_text
    cta_button_url
    cta_body_markdown
  ].freeze

  def create
    rate_limit!(:organization_creation)

    @tab = "organization"
    @user = current_user

    unless valid_image?
      render template: "users/edit"
      return
    end

    @organization = Organization.new(organization_params)
    authorize @organization
    if @organization.save
      rate_limiter.track_limit_by_action(:organization_creation)
      @organization_membership = OrganizationMembership.create!(organization_id: @organization.id,
                                                                user_id: current_user.id, type_of_user: "admin")
      flash[:settings_notice] = I18n.t("organizations_controller.created")
      redirect_to "/settings/organization/#{@organization.id}"
    else
      render template: "users/edit"
    end
  end

  def update
    @user = current_user
    @tab = "organization"
    set_organization

    unless valid_image?
      render template: "users/edit"
      return
    end

    if @organization.update(organization_params.merge(profile_updated_at: Time.current))
      @organization.users.touch_all(:organization_info_updated_at)
      flash[:settings_notice] = I18n.t("organizations_controller.updated")
      redirect_to "/settings/organization"
    else
      @org_organization_memberships = @organization.organization_memberships.includes(:user)
      @organization_membership = OrganizationMembership.find_by(user_id: current_user.id,
                                                                organization_id: @organization.id)

      render template: "users/edit"
    end
  end

  def destroy
    organization = Organization.find_by(id: params[:id])
    authorize organization

    Organizations::DeleteWorker.perform_async(organization.id, current_user.id, true)
    flash[:settings_notice] =
      I18n.t("organizations_controller.deletion_scheduled", organization_name: organization.name)

    redirect_to user_settings_path(:organization)
  rescue Pundit::NotAuthorizedError
    flash[:error] = I18n.t("organizations_controller.not_deleted")
    redirect_to user_settings_path(:organization, id: organization.id)
  end

  def generate_new_secret
    set_organization
    @organization.secret = @organization.generated_random_secret
    @organization.save
    flash[:settings_notice] = I18n.t("organizations_controller.secret_updated")
    redirect_to user_settings_path(:organization)
  end

  def members
    @organization = Organization.find_by(slug: params[:slug])
    @members = @organization.active_users

    respond_to do |format|
      format.json { render json: @members.to_json(only: %i[id name username]) }
      format.html
    end
  end

  def invite
    @organization = Organization.find_by(id: params[:id])
    not_found unless @organization
    authorize @organization, :update?

    username = params[:username]&.strip&.delete("@")
    @user = User.find_by(username: username)

    unless @user
      flash[:error] = I18n.t("organizations_controller.invite.user_not_found", username: username)
      redirect_to user_settings_path(:organization, org_id: @organization.id)
      return
    end

    # Check if user is already a member (active or pending)
    existing_membership = @organization.organization_memberships.find_by(user_id: @user.id)
    if existing_membership
      if existing_membership.pending?
        flash[:error] = I18n.t("organizations_controller.invite.already_pending")
      else
        flash[:error] = I18n.t("organizations_controller.invite.already_member")
      end
      redirect_to user_settings_path(:organization, org_id: @organization.id)
      return
    end

    # Rate limit check: only applies to non-fully-trusted organizations
    unless @organization.fully_trusted?
      # Check daily invitation limit
      today_start = Time.zone.now.beginning_of_day
      today_pending_count = @organization.organization_memberships
                                         .pending
                                         .where(created_at: today_start..)
                                         .count

      if today_pending_count >= Settings::RateLimit.organization_invitation_daily
        flash[:error] = I18n.t("organizations_controller.invite.rate_limit_exceeded",
                               limit: Settings::RateLimit.organization_invitation_daily)
        redirect_to user_settings_path(:organization, org_id: @organization.id)
        return
      end

      # Check total outstanding invitations limit
      total_pending_count = @organization.organization_memberships.pending.count
      if total_pending_count >= Settings::RateLimit.organization_invitation_max_outstanding
        flash[:error] = I18n.t("organizations_controller.invite.max_outstanding_exceeded",
                               limit: Settings::RateLimit.organization_invitation_max_outstanding)
        redirect_to user_settings_path(:organization, org_id: @organization.id)
        return
      end
    end

    # If organization is fully trusted, add user directly as member
    if @organization.fully_trusted?
      membership = @organization.organization_memberships.create!(
        user: @user,
        type_of_user: "member"
      )

      # Send notification email that they've been added
      OrganizationMembershipNotificationMailer.with(
        membership_id: membership.id
      ).member_added_email.deliver_now

      flash[:settings_notice] = I18n.t("organizations_controller.invite.added_success", username: @user.username)
    else
      # Create pending membership for regular organizations
      membership = @organization.organization_memberships.create!(
        user: @user,
        type_of_user: "pending"
      )

      # Send invitation email
      OrganizationInvitationMailer.with(membership_id: membership.id)
                                 .invitation_email
                                 .deliver_now

      flash[:settings_notice] = I18n.t("organizations_controller.invite.success", username: @user.username)
    end
    redirect_to user_settings_path(:organization, org_id: @organization.id)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.message
    redirect_to user_settings_path(:organization, org_id: @organization.id)
  end

  def confirm_invitation
    skip_authorization # Public action - no authorization needed
    @membership = OrganizationMembership.find_by(invitation_token: params[:token])
    
    unless @membership
      flash[:error] = I18n.t("organizations_controller.confirm_invitation.invalid_token")
      redirect_to root_path
      return
    end

    unless @membership.pending?
      flash[:error] = I18n.t("organizations_controller.confirm_invitation.already_confirmed")
      redirect_to root_path
      return
    end

    # If user is not signed in, show the confirmation page
    unless user_signed_in?
      render :confirm_invitation, status: :ok
      return
    end

    if current_user.id != @membership.user_id
      flash[:error] = I18n.t("organizations_controller.confirm_invitation.wrong_user")
      redirect_to root_path
      return
    end

    # Confirm the membership (POST request)
    if request.post?
      @membership.confirm!
      flash[:settings_notice] = I18n.t("organizations_controller.confirm_invitation.success",
                                        organization_name: @membership.organization.name)
      redirect_to user_settings_path(:organization, org_id: @membership.organization.id)
    else
      # GET request - show confirmation page
      render :confirm_invitation
    end
  end

  private

  def permitted_params
    ORGANIZATIONS_PERMITTED_PARAMS
  end

  def organization_params
    params.require(:organization).permit(permitted_params)
      .transform_values do |value|
        if value.instance_of?(String)
          ActionController::Base.helpers.strip_tags(value)
        else
          value
        end
      end
  end

  def set_organization
    @organization = Organization.find_by(id: organization_params[:id])
    not_found unless @organization
    authorize @organization
  end

  def valid_image?
    image = params.dig("organization", "profile_image")

    return true unless image

    if action_name == "create"
      @organization = Organization.new(organization_params.except(:profile_image))
      authorize @organization
    end

    return true if valid_image_file?(image) && valid_filename?(image)

    false
  end

  def valid_image_file?(image)
    return true if file?(image)

    @organization.errors.add(:profile_image, is_not_file_message)

    false
  end

  def valid_filename?(image)
    return true unless long_filename?(image)

    @organization.errors.add(:profile_image, filename_too_long_message)

    false
  end
end
