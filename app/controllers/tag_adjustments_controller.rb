class TagAdjustmentsController < ApplicationController
  def create
    authorize(User, :moderation_routes?)
    TagAdjustmentCreationService.new(
      current_user,
      adjustment_type: "removal",
      status: "committed",
      tag_name: params[:tag_adjustment][:tag_name],
      article_id: params[:tag_adjustment][:article_id],
      reason_for_adjustment: params[:tag_adjustment][:reason_for_adjustment],
    ).create
    @article = Article.find(params[:tag_adjustment][:article_id])
    redirect_to "#{@article.path}/mod"
  end

  def destroy
    authorize User, :moderation_routes?
    tag_adjustment = TagAdjustment.find(params[:id])
    tag_adjustment.destroy
    @article = Article.find(tag_adjustment.article_id)
    @article.update!(tag_list: @article.tag_list.add(tag_adjustment.tag_name))
    redirect_to "#{@article.path}/mod"
  end
end
