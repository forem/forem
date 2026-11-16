# Lets an invited user accept or decline an organization invitation from their notifications.
class OrganizationInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership
  after_action :verify_authorized

  # Joins the organization.
  def accept
    authorize @membership
    @membership.confirm!
    respond_with_result(success: true, notice: I18n.t("organization_invitations_controller.accepted",
                                                      organization_name: @organization.name))
  end

  # Removes the pending invitation.
  def decline
    authorize @membership
    @membership.destroy!
    respond_with_result(success: true, notice: I18n.t("organization_invitations_controller.declined",
                                                      organization_name: @organization.name))
  end

  private

  # Loads the current user's own pending invitation.
  def set_membership
    # Scoped to the current user's pending invitations so other people's, and answered ones, are
    # indistinguishable from missing ones.
    @membership = current_user.organization_memberships.pending.find(params[:id])
    @organization = @membership.organization
  end

  # Redirects back (HTML) or renders a status (JSON) after an answer.
  def respond_with_result(success:, notice:)
    respond_to do |format|
      format.html do
        flash[:global_notice] = notice if success
        redirect_back_or_to notifications_path
      end
      format.json { render json: { status: success ? "ok" : "error" } }
    end
  end
end
