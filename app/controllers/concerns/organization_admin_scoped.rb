module OrganizationAdminScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :set_organization
    before_action :authorize_admin!
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:slug])
    not_found unless @organization
  end

  def authorize_admin!
    authorize @organization, :update?, policy_class: OrganizationPolicy
  end
end
