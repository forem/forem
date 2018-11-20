class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  after_action :verify_authorized

  def create
    @tab = "organization"
    @user = current_user
    @tab_list = @user.settings_tab_list
    @organization = Organization.new(organization_params)
    authorize @organization
    if @organization.save
      current_user.update(organization_id: @organization.id, org_admin: true)
      redirect_to "/settings/organization", notice:
        "Your organization was successfully created and you are an admin."
    else
      @tab = "switch-organizations" if @user.has_role?(:switch_between_orgs)
      render template: "users/edit"
    end
  end

  # GET /users/:id/edit
  def update
    @user = current_user
    @tab = "organization"
    @tab_list = @user.settings_tab_list
    @organization = @user.organization
    authorize @organization

    if @organization.update(organization_params)
      redirect_to "/settings/organization", notice: "Your organization was successfully updated."
    else
      render template: "users/edit"
    end
  end

  def generate_new_secret
    raise unless current_user.org_admin
    @organization = current_user.organization
    authorize @organization
    @organization.secret = @organization.generated_random_secret
    @organization.save
    redirect_to "/settings/organization", notice: "Your org secret was updated"
  end

  private

  def permitted_params
    accessible = %i[
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
end
