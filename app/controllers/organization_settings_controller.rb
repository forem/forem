class OrganizationSettingsController < ApplicationController
  include ImageUploads
  include OrganizationAdminScoped

  before_action :check_org_verification_feature, only: [:request_verification]
  before_action :check_org_custom_domain_feature,
                only: %i[update_custom_domain remove_custom_domain check_custom_domain]

  CUSTOM_DOMAIN_CHECK_THROTTLE = 10.seconds

  def edit
    load_membership_data
  end

  def request_verification
    verification_url = params[:verification_url].to_s.strip

    if verification_url.blank?
      flash[:verification_error] = I18n.t("views.organization_settings.verification.url_required")
      redirect_to organization_settings_path(@organization.slug, anchor: "section-verification")
      return
    end

    if @organization.url.blank?
      flash[:verification_error] = I18n.t("views.organization_settings.verification.website_required")
      redirect_to organization_settings_path(@organization.slug, anchor: "section-verification")
      return
    end

    unless same_domain?(verification_url, @organization.url)
      flash[:verification_error] = I18n.t("views.organization_settings.verification.domain_mismatch")
      redirect_to organization_settings_path(@organization.slug, anchor: "section-verification")
      return
    end

    @organization.update_columns(verification_url: verification_url,
                                   verification_status: Organization::VERIFICATION_STATUS_PENDING, verification_error: nil)
    Organizations::VerifyLinkbackWorker.perform_async(@organization.id)

    flash[:verification_notice] = I18n.t("views.organization_settings.verification.check_started")
    redirect_to organization_settings_path(@organization.slug, anchor: "section-verification")
  end

  def update_custom_domain
    domain = normalized_custom_domain_param

    if domain.blank?
      flash[:custom_domain_error] = I18n.t("views.organization_settings.custom_domain.domain_required")
    elsif @organization.update(custom_domain: domain)
      flash[:custom_domain_notice] = I18n.t("views.organization_settings.custom_domain.saved")
    else
      flash[:custom_domain_error] = @organization.errors.full_messages.to_sentence
    end

    redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
  end

  def remove_custom_domain
    if @organization.update(custom_domain: nil)
      flash[:custom_domain_notice] = I18n.t("views.organization_settings.custom_domain.removed")
    else
      flash[:custom_domain_error] = @organization.errors.full_messages.to_sentence
    end

    redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
  end

  def check_custom_domain
    if @organization.custom_domain.blank?
      redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
      return
    end

    throttle_key = "org_custom_domain_check:#{@organization.id}"
    unless Rails.cache.write(throttle_key, true, expires_in: CUSTOM_DOMAIN_CHECK_THROTTLE, unless_exist: true)
      flash[:custom_domain_notice] = I18n.t("views.organization_settings.custom_domain.check_throttled")
      redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
      return
    end

    if @organization.failed?
      @organization.restart_custom_domain_provisioning!
      flash[:custom_domain_notice] = I18n.t("views.organization_settings.custom_domain.retry_started")
    elsif @organization.cloudflare_custom_hostname_id.blank? && @organization.tls_subscription_id.blank?
      Organizations::ProvisionCustomDomainWorker.perform_async(@organization.id) if @organization.pending?
      flash[:custom_domain_notice] = I18n.t("views.organization_settings.custom_domain.check_started")
    else
      Organizations::VerifyCustomDomainWorker.new.perform(@organization.id)
      @organization.reload
      flash[:custom_domain_notice] = if @organization.issued?
                                       I18n.t("views.organization_settings.custom_domain.check_live")
                                     else
                                       I18n.t("views.organization_settings.custom_domain.check_pending")
                                     end
    end

    redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
  rescue CloudflareSaas::Client::Error, FastlyTls::Client::Error => e
    Rails.logger.error("[OrganizationSettings] Custom domain check failed for org #{@organization.id}: #{e.message}")
    flash[:custom_domain_error] = I18n.t("views.organization_settings.custom_domain.check_error")
    redirect_to organization_settings_path(@organization.slug, anchor: "section-custom-domain")
  end

  def preview
    renderer = ContentRenderer.new(params[:body_markdown].to_s, source: @organization, user: current_user)
    result = renderer.process
    render json: { processed_html: result.processed_html }
  rescue ContentRenderer::ContentParsingError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    unless valid_image?
      load_membership_data
      render :edit
      return
    end

    was_verified = @organization.verified?
    if @organization.update(organization_params.merge(profile_updated_at: Time.current))
      @organization.users.touch_all(:organization_info_updated_at)
      notice = I18n.t("organizations_controller.updated")
      if was_verified && !@organization.verified?
        notice += " " + I18n.t("views.organization_settings.verification.reset_on_domain_change")
      end
      flash[:settings_notice] = notice
      redirect_to organization_settings_path(@organization.slug)
    else
      load_membership_data
      render :edit
    end
  end

  private

  def load_membership_data
    @org_organization_memberships = @organization.organization_memberships.includes(:user)
    @organization_membership = OrganizationMembership.find_by(
      user_id: current_user.id,
      organization_id: @organization.id,
    )
  end

  def organization_params
    permitted = params.require(:organization).permit(
      :name, :summary, :tag_line, :slug, :url, :proof, :profile_image,
      :location, :company_size, :tech_stack, :email, :story,
      :bg_color_hex, :text_color_hex, :twitter_username, :github_username,
      :cta_button_text, :cta_button_url, :cta_body_markdown,
      :cover_image, :remove_cover_image,
      social_links: Organization::SOCIAL_LINK_PLATFORMS,
      header_cta: [:text, :url, links: [:text, :url, :logo_url]],
    )

    unless FeatureFlag.enabled?(:org_readme, FeatureFlag::Actor[@organization])
      permitted.delete(:cover_image)
      permitted.delete(:remove_cover_image)
    end

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

  def same_domain?(url1, url2)
    UrlDomainHelper.same_domain?(url1, url2)
  end

  def check_org_verification_feature
    not_found unless FeatureFlag.enabled?(:org_verification, FeatureFlag::Actor[@organization])
  end

  def check_org_custom_domain_feature
    not_found unless custom_domain_settings_enabled?
  end

  def custom_domain_settings_enabled?
    CloudflareSaas.enabled? && FeatureFlag.enabled?(:org_custom_domain, FeatureFlag::Actor[@organization])
  end
  helper_method :custom_domain_settings_enabled?

  # Accept pasted URLs like "https://blog.example.com/" by keeping only the host.
  def normalized_custom_domain_param
    value = params.dig(:organization, :custom_domain).to_s.strip.downcase
    value = value.sub(%r{\A[a-z][a-z0-9+.-]*://}, "")
    value.split(%r{[/?#]}).first.to_s.chomp(".")
  end
end
