class TagAdjustmentCreationService
  def initialize(user, tag_adjustment_params)
    @user = user
    @tag_adjustment_params = tag_adjustment_params
  end

  def create
    tag_adjustment = TagAdjustment.create(creation_args)
    Notification.send_tag_adjustment_notification(tag_adjustment)
    tag_adjustment
  end

  private

  def creation_args
    args = @tag_adjustment_params
    args[:user_id] = @user.id
    args[:tag_id] = Tag.find_by_name(args[:tag_name])&.id
    args
  end
end
