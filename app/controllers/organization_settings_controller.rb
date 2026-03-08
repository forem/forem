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

  def preview
    renderer = ContentRenderer.new(params[:body_markdown].to_s, source: @organization, user: current_user)
    result = renderer.process
    @preview_html = result.processed_html
    render layout: "application"
  rescue ContentRenderer::ContentParsingError => e
    @preview_error = e.message
    render layout: "application"
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
    permitted = params.require(:organization).permit(
      :name, :summary, :tag_line, :slug, :url, :proof, :profile_image,
      :location, :company_size, :tech_stack, :email, :story,
      :bg_color_hex, :text_color_hex, :twitter_username, :github_username,
      :cta_button_text, :cta_button_url, :cta_body_markdown,
      :cover_image, :page_markdown,
      social_links: Organization::SOCIAL_LINK_PLATFORMS,
      header_cta: [:text, :url, links: [:text, :url, :logo_url]],
    )

    result = permitted.to_h
    result.transform_values! do |value|
      value.instance_of?(String) ? ActionController::Base.helpers.strip_tags(value) : value
    end

    if result["social_links"].present?
      result["social_links"] = result["social_links"].transform_values do |v|
        ActionController::Base.helpers.strip_tags(v.to_s).strip
      end.reject { |_, v| v.blank? }
    end

    if result["header_cta"].present?
      cta = result["header_cta"]
      cta["text"] = ActionController::Base.helpers.strip_tags(cta["text"].to_s).strip if cta["text"]
      cta["url"] = ActionController::Base.helpers.strip_tags(cta["url"].to_s).strip if cta["url"]

      if cta["links"].present?
        cta["links"] = cta["links"].select { |l| l["text"].present? && l["url"].present? }.map do |link|
          link.transform_values { |v| ActionController::Base.helpers.strip_tags(v.to_s).strip }
        end
        cta.delete("links") if cta["links"].empty?
      end

      # Clear the CTA entirely if the text is blank
      result["header_cta"] = cta["text"].present? ? cta : {}
    end

    result
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
