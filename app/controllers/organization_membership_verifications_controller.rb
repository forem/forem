class OrganizationMembershipVerificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :private_response

  def show
    @challenge = OrganizationMembershipChallenge.joins(:organization_email_domain)
      .where(user: current_user, consumed_at: nil, expires_at: Time.current..)
      .where(organization_email_domains: { organization_id: @organization.id }).order(created_at: :desc).first
    @membership = @organization.organization_memberships.find_by(user: current_user)
  end

  def create
    service.request_code(params[:work_email])
    redirect_to organization_join_path(@organization.slug), notice: I18n.t("org_domain_membership.code_sent")
  rescue Organizations::DomainMembership::Error => e
    redirect_to organization_join_path(@organization.slug), alert: I18n.t("org_domain_membership.errors.#{e.message}")
  end

  def update
    service.verify(params[:challenge_id], params[:otp])
    redirect_to organization_join_path(@organization.slug), notice: I18n.t("org_domain_membership.joined")
  rescue Organizations::DomainMembership::Error => e
    redirect_to organization_join_path(@organization.slug), alert: I18n.t("org_domain_membership.errors.#{e.message}")
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:slug])
  end

  def private_response
    response.headers["Cache-Control"] = "private, no-store"
  end

  def service
    Organizations::DomainMembership.new(user: current_user, organization: @organization)
  end
end
