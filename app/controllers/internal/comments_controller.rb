class Internal::CommentsController < Internal::ApplicationController
  layout "internal"

  def index
    @comments = if params[:state]&.start_with?("toplast-")
                  Comment.
                    includes(:user).
                    includes(:commentable).
                    order("positive_reactions_count DESC").
                    where("created_at > ?", params[:state].split("-").last.to_i.days.ago).
                    page(params[:page] || 1).per(50)
                else
                  Comment.
                    includes(:user).
                    includes(:commentable).
                    order("created_at DESC").
                    page(params[:page] || 1).per(50)
                end
  end

  private

  def authorize_admin
    authorize Comment, :access?, policy_class: InternalPolicy
  end
end
