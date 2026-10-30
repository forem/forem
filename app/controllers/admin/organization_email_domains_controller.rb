module Admin
  class OrganizationEmailDomainsController < Admin::ApplicationController
    layout "admin"

    def index
      @domains = OrganizationEmailDomain.includes(:organization, :requested_by, :reviewed_by)
        .order(Arel.sql("CASE WHEN status = 'pending' THEN 0 ELSE 1 END"), created_at: :desc)
        .page(params[:page]).per(50)
    end

    def update
      domain = OrganizationEmailDomain.find(params[:id])
      decision = params[:decision].to_s
      raise ActionController::BadRequest unless %w[approved rejected revoked].include?(decision)

      domain.review!(current_user, decision)
      redirect_to admin_organization_email_domains_path, notice: I18n.t("org_domain_membership.review_saved")
    end

    protected

    def authorize_admin
      authorize OrganizationEmailDomain, :review?, policy_class: OrganizationEmailDomainPolicy
    end
  end
end
