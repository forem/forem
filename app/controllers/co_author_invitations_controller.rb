class CoAuthorInvitationsController < ApplicationController
  CANDIDATES_LIMIT = 8

  before_action :authenticate_user!
  before_action :set_invitation, only: %i[accept decline]
  after_action :verify_authorized

  # Followers of the current user matching ?search, for the editor's co-author picker.
  def candidates
    authorize CoAuthorInvitation
    return not_found unless feature_flag_enabled?(:co_author_invitations)

    users = CoAuthorInvitation.eligible_invitees_for(current_user)
      .search_by_name_and_username(params[:search])
      .select(:id, :name, :username, :profile_image)
      .order(score: :desc)
      .limit(CANDIDATES_LIMIT)

    render json: users.map { |user| helpers.co_author_invitee_data(user) }
  end

  def accept
    authorize @invitation
    respond_to_response(CoAuthorInvitations::Accept.call(@invitation))
  end

  def decline
    authorize @invitation
    respond_to_response(CoAuthorInvitations::Decline.call(@invitation))
  end

  private

  def set_invitation
    # Scoped to the current user so other people's invitations are indistinguishable from missing ones.
    @invitation = current_user.co_author_invitations.find(params[:id])
  end

  def respond_to_response(success)
    respond_to do |format|
      format.html do
        flash[:global_notice] = I18n.t("co_author_invitations_controller.not_updated") unless success
        redirect_back_or_to notifications_path
      end
      format.json do
        if success
          render json: { status: @invitation.status }
        else
          render json: { error: I18n.t("co_author_invitations_controller.not_updated") }, status: :unprocessable_entity
        end
      end
    end
  end
end
