class OrganizationsController < ApplicationController
  after_action :verify_authorized
  rescue_from Errno::ENAMETOOLONG, with: :handle_name_too_long

  def create
    rate_limit!(:organization_creation)
    set_user_info
    @form = OrganizationForm.new(organization_attributes: organization_params, current_user: current_user)
    @organization = @form.organization
    authorize @organization
    if @form.save
      rate_limiter.track_limit_by_action(:organization_creation)
      flash[:settings_notice] = "Your organization was successfully created and you are an admin."
      redirect_to "/settings/organization/#{@organization.id}"
    else
      render template: "users/edit"
    end
  end

  def update
    set_user_info
    @form = OrganizationForm.new(organization_attributes: organization_params.merge(profile_updated_at: Time.current), current_user: current_user)
    set_organization
    if @form.save
      flash[:settings_notice] = "Your organization was successfully updated."
      redirect_to "/settings/organization"
    else
      render template: "users/edit"
    end
  end

  def generate_new_secret
    set_organization
    @organization.secret = @organization.generated_random_secret
    @organization.save
    flash[:settings_notice] = "Your org secret was updated"
    redirect_to "/settings/organization"
  end

  private

  def handle_name_too_long
    log_image_data_to_datadog
  rescue Errno::ENAMETOOLONG
    @form.organization.errors.add(:profile_image, FILENAME_TOO_LONG_MESSAGE)
    render template: "users/edit"
  end

  def set_user_info
    @user = current_user
    @tab = "organization"
    @tab_list = @user.settings_tab_list
  end

  def permitted_params
    accessible = %i[
      id
      name
      summary
      tag_line
      slug
      url
      proof
      profile_image
      nav_image
      dark_nav_image
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
    ]
    accessible
  end

  def organization_params
    params.require(:organization).permit(permitted_params).
      transform_values do |value|
        if value.class.name == "String"
          ActionController::Base.helpers.strip_tags(value)
        else
          value
        end
      end
  end

  def set_organization
    @organization = @form&.organization || Organization.find_by(id: organization_params[:id])
    not_found unless @organization
    @organization_membership = OrganizationMembership.find_by(user_id: current_user.id, organization_id: @organization.id)
    @org_organization_memberships = @organization.organization_memberships.includes(:user)
    authorize @organization
  end
end
