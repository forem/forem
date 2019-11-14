class TagAdjustmentsController < ApplicationController
  def create
    authorize(User, :moderation_routes?)
    service = TagAdjustmentCreationService.new(
      current_user,
      adjustment_type: params[:tag_adjustment][:adjustment_type],
      status: "committed",
      tag_name: params[:tag_adjustment][:tag_name],
      article_id: params[:tag_adjustment][:article_id],
      reason_for_adjustment: params[:tag_adjustment][:reason_for_adjustment],
    )
    if service.tag_adjustment.save
      service.create
    else
      errors = service.tag_adjustment.errors.full_messages.join(", ")
      flash[:error_removal] = errors if service.tag_adjustment.adjustment_type == "removal"
      flash[:error_addition] = errors if service.tag_adjustment.adjustment_type == "addition"
    end
    @article = Article.find(params[:tag_adjustment][:article_id])
    redirect_to "#{URI.parse(@article.path).path}/mod"
  end

  def destroy
    authorize User, :moderation_routes?
    tag_adjustment = TagAdjustment.find(params[:id])
    tag_adjustment.destroy
    @article = Article.find(tag_adjustment.article_id)
    @article.update!(tag_list: @article.tag_list.add(tag_adjustment.tag_name)) if tag_adjustment.adjustment_type == "removal"
    @article.update!(tag_list: @article.tag_list.remove(tag_adjustment.tag_name)) if tag_adjustment.adjustment_type == "addition"
    redirect_to "#{URI.parse(@article.path).path}/mod"
  end
end
