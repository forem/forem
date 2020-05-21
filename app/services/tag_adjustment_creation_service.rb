class TagAdjustmentCreationService
  def initialize(user, tag_adjustment_params)
    @user = user
    @tag_adjustment_params = tag_adjustment_params
  end

  def tag_adjustment
    @tag_adjustment ||= TagAdjustment.new(creation_args)
  end

  def article
    @article ||= Article.find(@tag_adjustment_params[:article_id])
  end

  def update_tags_and_notify
    update_article
    Notification.send_tag_adjustment_notification(tag_adjustment)
  end

  private

  def update_article
    if @tag_adjustment.adjustment_type == "removal"
      removed_tags = article.tag_list.select { |tag| tag.casecmp(@tag_adjustment.tag_name).zero? }
      return if removed_tags.empty?

      article.update!(tag_list: article.tag_list.remove(removed_tags))
    end

    article.update!(tag_list: article.tag_list.add(@tag_adjustment.tag_name)) if @tag_adjustment.adjustment_type == "addition"
  end

  def creation_args
    args = @tag_adjustment_params

    tag =
      case args[:adjustment_type]
      when "removal"
        article.tags.detect { |article_tag| article_tag.name.casecmp(args[:tag_name]).zero? }
      when "addition"
        Tag.find_by(name: args[:tag_name])
      end

    args[:user_id] = @user.id
    args[:tag_id] = tag&.id
    args[:tag_name] = tag&.name || args[:tag_name]
    args
  end
end
