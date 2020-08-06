module Admin
  class OrganizationMembershipsController < Admin::ApplicationController
    layout "admin"

    def update
      organization_membership = OrganizationMembership.find_by(id: params[:id])
      if organization_membership.update(organization_membership_params)
        flash[:success] = "User was successfully updated to #{organization_membership.type_of_user}"
      else
        flash[:danger] = organization_membership.errors.full_messages
      end
      redirect_to admin_user_path(organization_membership.user_id)
    end

    def create
      organization_membership = OrganizationMembership.new(organization_membership_params)
      organization = Organization.find_by(id: organization_membership_params[:organization_id])
      if organization && organization_membership.save
        flash[:success] = "User was successfully added to #{organization.name}"
      elsif organization.blank?
        message = "Organization ##{organization_membership_params[:organization_id]} does not exist. Perhaps a typo?"
        flash[:danger] = message
      else
        flash[:danger] = organization_membership.errors.full_messages
      end
      redirect_to admin_user_path(organization_membership.user_id)
    end

    def destroy
      organization_membership = OrganizationMembership.find_by(id: params[:id])
      if organization_membership.destroy
        flash[:success] = "User was successfully removed from org ##{organization_membership.organization_id}"
      else
        message = "Something went wrong with removing the user from org ##{organization_membership.organization_id}"
        flash[:danger] = message
      end
      redirect_to admin_user_path(organization_membership.user_id)
    end

    private

    def organization_membership_params
      allowed_params = %i[type_of_user user_title organization_id user_id]
      params.require(:organization_membership).permit(allowed_params)
    end
  end
end
