class OrganizationsController < ApplicationController
  after_action :verify_authorized

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
      flash[:settings_notice] = "Your organization was successfully created and you are an admin."
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
      flash[:settings_notice] = "Your organization was successfully updated."
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
    if organization.destroy
      current_user.touch(:organization_info_updated_at)
      CacheBuster.bust_user(current_user)
      flash[:settings_notice] = "Your organization: \"#{organization.name}\" was successfully deleted."
      redirect_to user_settings_path(:organization)
    else
      flash[:settings_notice] = "#{organization.errors.full_messages.to_sentence}.
        Please email #{SiteConfig.email_addresses[:contact]} for assistance."
      redirect_to user_settings_path(:organization, id: organization.id)
    end
  rescue Pundit::NotAuthorizedError
    flash[:error] = "Your organization was not deleted; you must be an admin, the only member in the organization,
      and have no articles connected to the organization."
    redirect_to user_settings_path(:organization, id: organization.id)
  end

  def generate_new_secret
    set_organization
    @organization.secret = @organization.generated_random_secret
    @organization.save
    flash[:settings_notice] = "Your org secret was updated"
    redirect_to user_settings_path(:organization)
  end

  private

  def permitted_params
    %i[
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

    @organization.errors.add(:profile_image, IS_NOT_FILE_MESSAGE)

    false
  end

  def valid_filename?(image)
    return true unless long_filename?(image)

    @organization.errors.add(:profile_image, FILENAME_TOO_LONG_MESSAGE)

    false
  end
end
