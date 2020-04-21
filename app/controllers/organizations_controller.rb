class OrganizationsController < ApplicationController
  after_action :verify_authorized
  rescue_from Errno::ENAMETOOLONG, with: :log_image_data_to_datadog

  def create
    @tab = "organization"
    @user = current_user
    @tab_list = @user.settings_tab_list

    unless valid_filename?
      render template: "users/edit"
      return
    end

    @organization = Organization.new(organization_params)
    authorize @organization
    if @organization.save
      @organization_membership = OrganizationMembership.create!(organization_id: @organization.id, user_id: current_user.id, type_of_user: "admin")
      flash[:settings_notice] = "Your organization was successfully created and you are an admin."
      redirect_to "/settings/organization/#{@organization.id}"
    else
      render template: "users/edit"
    end
  end

  def update
    @user = current_user
    @tab = "organization"
    @tab_list = @user.settings_tab_list
    set_organization

    unless valid_filename?
      render template: "users/edit"
      return
    end

    if @organization.update(organization_params.merge(profile_updated_at: Time.current))
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
    @organization = Organization.find_by(id: organization_params[:id])
    not_found unless @organization
    authorize @organization
  end

  def valid_filename?
    image = params.dig("organization", "profile_image")
    return true unless long_filename?(image)

    if action_name == "create"
      @organization = Organization.new(organization_params.except(:profile_image))
      authorize @organization
    end

    @organization.errors.add(:profile_image, FILENAME_TOO_LONG_MESSAGE)
    false
  end
end
