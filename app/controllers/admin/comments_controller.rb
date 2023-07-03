module Admin
  class CommentsController < Admin::ApplicationController
    layout "admin"

    def index
      @comments = if params[:state]&.start_with?("toplast-")
                    Comment
                      .includes(:user)
                      .includes(:commentable)
                      .order(public_reactions_count: :desc)
                      .where("created_at > ?", params[:state].split("-").last.to_i.days.ago)
                      .page(params[:page] || 1).per(50)
                  else
                    Comment
                      .includes(:user)
                      .includes(:commentable)
                      .order(created_at: :desc)
                      .page(params[:page] || 1).per(50)
                  end
    end

    def show
      @comment = Comment.includes(:user, :commentable).find(params[:id])
    end

    private

    def authorize_admin
      authorize Comment, :access?, policy_class: InternalPolicy
    end
  end
end
