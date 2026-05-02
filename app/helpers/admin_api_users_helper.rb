module AdminApiUsersHelper
  STATUS_PRIORITY = %w[suspended spam warned comment_suspended limited trusted].freeze

  # Returns the user's current moderation status as a snake_case string.
  # Uses .map(&:name) so it operates on Rolify's eager-loaded roles association
  # (see Api::Admin::UsersController#index) without firing a query per status.
  # We avoid User#has_role? because it's private on Forem's User model.
  def user_moderation_status(user)
    role_names = user.roles.map(&:name)
    STATUS_PRIORITY.find { |r| role_names.include?(r) } || "good_standing"
  end
end
