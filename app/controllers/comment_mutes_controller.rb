class CommentMutesController < ApplicationController
  after_action :verify_authorized

  def update
    @comment = Comment.find_by(id: params[:id])
    authorize @comment
    related_comments_ids = @comment.subtree.union(@comment.ancestors).where(user_id: @comment.user_id).pluck(:id)
    Comment.where(id: related_comments_ids).update_all(receive_notifications: permitted_attributes(@comment)[:receive_notifications])
    redirect_to "#{@comment.path}/settings"
  end
end
