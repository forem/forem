class CommentObserver < ActiveRecord::Observer
  def after_save(comment)
    return if Rails.env.development?
    if comment.user.warned == true
      SlackBot.delay.ping "@#{comment.user.username} just posted a comment.\nThey've been warned since #{comment.user.roles.where(name: 'warned')[0].updated_at.strftime('%d %B %Y')}\nhttps://dev.to#{comment.path}",
              channel: "warned-user-activity",
              username: "sloan_watch_bot",
              icon_emoji: ":sloan:"
    end
  rescue StandardError
    puts "error"
  end
end
