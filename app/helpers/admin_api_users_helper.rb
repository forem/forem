module AdminApiUsersHelper
  STATUS_PRIORITY = %w[suspended spam warned comment_suspended limited trusted].freeze

  def user_moderation_status(user)
    role = STATUS_PRIORITY.detect { |r| user.roles.exists?(name: r) }
    role || "good_standing"
  end
end
