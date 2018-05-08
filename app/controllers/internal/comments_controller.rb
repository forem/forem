class Internal::CommentsController < Internal::ApplicationController
  layout 'internal'

  def index
    if params[:state]&.start_with?("toplast-")
      @comments = Comment.
        includes(:user).
        includes(:commentable).
        includes(:reactions).
        order("positive_reactions_count DESC").
        where("created_at > ?", params[:state].split("-").last.to_i.days.ago).
        page(params[:page] || 1).per(50)
    else
      @comments = Comment
                  .includes(:user)
                  .includes(:commentable)
                  .includes(:reactions)
                  .order("created_at DESC")
                  .page(params[:page] || 1).per(50)
    end
  end
end
