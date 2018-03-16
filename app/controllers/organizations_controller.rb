class OrganizationsController < ApplicationController
  before_action :authenticate_user!, except: [:show]

  def create
    @tab = "organization"
    @user = current_user
    @tab_list = tab_list(@user)
    @organization = Organization.new(organization_params)
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
    @tab_list = tab_list(@user)
    raise unless @user.org_admin
    @organization = @user.organization
    if @organization.update(organization_params)
      redirect_to "/settings/organization", notice: "Your organization was successfully updated."
    else
      render template: "users/edit"
    end
  end

  def generate_new_secret
    raise unless current_user.org_admin
    @organization = current_user.organization
    @organization.secret = @organization.generated_random_secret
    @organization.save
    redirect_to "/settings/organization", notice: "Your org secret was updated"
  end

  private

  def organization_params
    params.require(:organization).permit(:name,
                                          :summary,
                                          :tag_line,
                                          :slug,
                                          :url,
                                          :proof,
                                          :profile_image,
                                          :location,
                                          :company_size,
                                          :tech_stack,
                                          :email,
                                          :story,
                                          :bg_color_hex,
                                          :text_color_hex,
                                          :twitter_username,
                                          :github_username).
      transform_values do |value|
        if value.class.name == "String"
          ActionController::Base.helpers.strip_tags(value)
        else
          value
        end
      end
  end
end
