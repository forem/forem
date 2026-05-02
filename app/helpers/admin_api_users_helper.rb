module AdminApiUsersHelper
  # Highest-priority role first; values match the strings accepted by the
  # PUT /api/admin/users/:id/status endpoint and Moderator::ManageActivityAndRoles.
  STATUS_PRIORITY = {
    "suspended" => "Suspended",
    "spam" => "Spam",
    "warned" => "Warned",
    "comment_suspended" => "Comment Suspended",
    "limited" => "Limited",
    "trusted" => "Trusted"
  }.freeze

  # Operates on the eager-loaded roles association (no query per status).
  # User#has_role? is private on Forem's User model, hence the manual lookup.
  def user_moderation_status(user)
    role_names = user.roles.map(&:name)
    matched = STATUS_PRIORITY.detect { |role, _label| role_names.include?(role) }
    matched ? matched.last : "Good standing"
  end
end
