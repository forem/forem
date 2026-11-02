class OrganizationEmailDomainsController < ApplicationController
  include OrganizationAdminScoped

  def create
    domain = @organization.organization_email_domains.find_or_initialize_by(domain: params[:domain].to_s.strip.downcase)
    saved = false
    domain.with_lock do
      if domain.new_record? || %w[rejected revoked].include?(domain.status)
        saved = domain.update(domain: params[:domain], requested_by: current_user, status: "pending",
                              enabled: false, reviewed_by: nil, reviewed_at: nil)
      end
    end
    if saved
      flash[:settings_notice] = I18n.t("org_domain_membership.requested")
    else
      flash[:error] = domain.errors.full_messages.to_sentence.presence ||
        I18n.t("org_domain_membership.already_requested")
    end
    redirect_to organization_settings_path(@organization.slug, anchor: "section-email-domains")
  end

  def update
    domain = @organization.organization_email_domains.find(params[:id])
    domain.with_lock do
      if domain.status == "approved"
        domain.update!(enabled: params[:enabled] == "true")
        domain.organization_membership_challenges.where(consumed_at: nil).update_all(expires_at: Time.current)
      end
    end
    redirect_to organization_settings_path(@organization.slug, anchor: "section-email-domains")
  end

  def destroy
    domain = @organization.organization_email_domains.find(params[:id])
    domain.with_lock do
      domain.update!(status: "revoked", enabled: false)
      domain.organization_membership_challenges.where(consumed_at: nil).update_all(expires_at: Time.current)
    end
    redirect_to organization_settings_path(@organization.slug, anchor: "section-email-domains")
  end
end
