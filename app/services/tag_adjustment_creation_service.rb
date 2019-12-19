class TagAdjustmentCreationService
  def initialize(user, tag_adjustment_params)
    @user = user
    @tag_adjustment_params = tag_adjustment_params
  end

  def tag_adjustment
    @tag_adjustment ||= TagAdjustment.new(creation_args)
  end

  def article
    @article ||= Article.find(creation_args[:article_id])
  end

  def update_tags_and_notify
    update_article
    Notification.send_tag_adjustment_notification(tag_adjustment)
  end

  private

  def update_article
    article.update!(tag_list: article.tag_list.remove(@tag_adjustment.tag_name)) if @tag_adjustment.adjustment_type == "removal"
    article.update!(tag_list: article.tag_list.add(@tag_adjustment.tag_name)) if @tag_adjustment.adjustment_type == "addition"
  end

  def creation_args
    args = @tag_adjustment_params
    args[:user_id] = @user.id
    args[:tag_id] = Tag.find_by(name: args[:tag_name])&.id
    args
  end
end
