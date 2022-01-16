class TagAdjustmentsController < ApplicationController
  after_action only: %i[create destroy] do
    Audit::Logger.log(:moderator, current_user, params.dup)
  end

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
    tag_adjustment = service.tag_adjustment
    article = service.article
    if tag_adjustment.save
      service.update_tags_and_notify
      tag = tag_adjustment.tag
      respond_to do |format|
        format.json do
          render json: { status: "Success", result: tag_adjustment.adjustment_type,
                         colors: { bg: tag.bg_color_hex, text: tag.text_color_hex } }
        end
        format.html { redirect_to "#{Addressable::URI.parse(article.path).path}/mod" }
      end
    else
      # TODO: remove this when we move over to full JSON endpoint
      authorize(User, :moderation_routes?)
      @tag_adjustment = tag_adjustment
      @moderatable = article
      @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
      @adjustments = TagAdjustment.where(article_id: article.id)
      @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
      @allowed_to_adjust = @moderatable.instance_of?(Article) && (current_user.any_admin? || @tag_moderator_tags.any?)
      respond_to do |format|
        format.json do
          render json: { error: I18n.t("tag_adjustments_controller.failure",
                                       errors: tag_adjustment.errors.full_messages.to_sentence) }
        end
        format.html { render template: "moderations/mod" }
      end
    end
  end

  def destroy
    authorize User, :moderation_routes?

    adjustment = TagAdjustment.find(params[:id])
    adjustment.destroy

    @article = Article.find(adjustment.article_id)

    removal_type = adjustment.adjustment_type == "removal"
    @article.update!(tag_list: @article.tag_list.add(adjustment.tag_name)) if removal_type

    addition_type = adjustment.adjustment_type == "addition"
    @article.update!(tag_list: @article.tag_list.remove(adjustment.tag_name)) if addition_type

    respond_to do |format|
      # TODO: add tag adjustment removal async route in actions panel
      format.json { render json: { result: I18n.t("tag_adjustments_controller.destroyed") } }
      format.html { redirect_to "#{Addressable::URI.parse(@article.path).path}/mod" }
    end
  end
end
