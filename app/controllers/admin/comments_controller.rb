module Admin
  class CommentsController < Admin::ApplicationController
    def update
      comment = Comment.find(params[:id])
      if comment.update(comment_params)
        flash[:notice] = "Comment successfully updated"
        redirect_to "/admin/comments/#{comment.id}"
      else
        flash.now[:error] = comment.errors.full_messages
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, comment) }
      end
    end

    private

    def comment_params
      accessible = %i[user_id body_markdown deleted score]
      params.require(:comment).permit(accessible)
    end
  end
end
