class TagAdjustmentsController < ApplicationController
  def create
    authorize(User, :moderation_routes?)
    TagAdjustmentCreationService.new(current_user, {
      adjustment_type: "removal",
      status: "committed",
      tag_name: params[:tag_adjustment][:tag_name],
      article_id: params[:tag_adjustment][:article_id]
    }).create
    @article = Article.find(params[:tag_adjustment][:article_id])
    redirect_to "#{@article.path}/mod"
  end
end
