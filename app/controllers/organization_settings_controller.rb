class OrganizationSettingsController < ApplicationController
  include ImageUploads

  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!

  def edit
    @org_organization_memberships = @organization.organization_memberships.includes(:user)
    @organization_membership = OrganizationMembership.find_by(
      user_id: current_user.id,
      organization_id: @organization.id,
    )
  end

  def update
    unless valid_image?
      @org_organization_memberships = @organization.organization_memberships.includes(:user)
      @organization_membership = OrganizationMembership.find_by(
        user_id: current_user.id,
        organization_id: @organization.id,
      )
      render :edit
      return
    end

    if @organization.update(organization_params.merge(profile_updated_at: Time.current))
      @organization.users.touch_all(:organization_info_updated_at)
      flash[:settings_notice] = I18n.t("organizations_controller.updated")
      redirect_to organization_settings_path(@organization.slug)
    else
      @org_organization_memberships = @organization.organization_memberships.includes(:user)
      @organization_membership = OrganizationMembership.find_by(
        user_id: current_user.id,
        organization_id: @organization.id,
      )
      render :edit
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:slug])
    not_found unless @organization
  end

  def authorize_admin!
    authorize @organization, :update?, policy_class: OrganizationPolicy
  end

  def organization_params
    params.require(:organization).permit(
      :name, :summary, :tag_line, :slug, :url, :proof, :profile_image,
      :location, :company_size, :tech_stack, :email, :story,
      :bg_color_hex, :text_color_hex, :twitter_username, :github_username,
      :cta_button_text, :cta_button_url, :cta_body_markdown,
      :cover_image, :page_markdown,
    ).transform_values do |value|
      if value.instance_of?(String)
        ActionController::Base.helpers.strip_tags(value)
      else
        value
      end
    end
  end

  def valid_image?
    valid_upload?(:profile_image) && valid_upload?(:cover_image)
  end

  def valid_upload?(field)
    image = params.dig("organization", field.to_s)
    return true unless image

    unless file?(image)
      @organization.errors.add(field, is_not_file_message)
      return false
    end

    if long_filename?(image)
      @organization.errors.add(field, filename_too_long_message)
      return false
    end

    true
  end
end
