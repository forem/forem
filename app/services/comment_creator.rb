require "delegate"

class CommentCreator < Delegator
  attr_reader :record
  alias __getobj__ record

  def self.build_comment(params, current_user:)
    new(params, current_user: current_user)
  end

  # rubocop:disable Lint/MissingSuper
  def initialize(params, current_user:)
    @current_user = current_user
    @params = params
    @record = comment
  end
  # rubocop:enable Lint/MissingSuper

  def save
    return unless record.save

    check_code_of_conduct
    create_first_reaction
    notify_subscribers

    # copying this from the controller even though it seems impossible?
    if record.invalid?
      record.destroy
      return self
    end

    self
  end

  private

  attr_reader :current_user, :params

  def check_code_of_conduct
    checked_code_of_conduct = params[:checked_code_of_conduct].present? && !current_user.checked_code_of_conduct
    current_user.update(checked_code_of_conduct: true) if checked_code_of_conduct
  end

  def comment
    @comment ||= Comment.build_comment params.merge(user: current_user)
  end

  def create_first_reaction
    Reaction.create user: current_user, category: "like", reactable: @comment
  end

  def notify_subscribers
    NotificationSubscription.create config: "all_comments",
                                    notifiable_id: @comment.id,
                                    notifiable_type: "Comment",
                                    user: current_user
    Notification.send_new_comment_notifications_without_delay(@comment)
    Mention.create_all(@comment)
  end
end
