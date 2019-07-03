class CommentObserver < ApplicationObserver
  def after_create(comment)
    return if Rails.env.development?

    warned_user_ping(comment)
  rescue StandardError => e
    Rails.logger.error(e)
  end
end
