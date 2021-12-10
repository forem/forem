# Intentionally not inheriting from ApplicationPolicy because liquid tags behave
# differently than the typical Model/Controller dynamic that Pundit assumes.
class LiquidTagPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def initialize?
    return true unless record.user_authorization_method_name
    raise Pundit::NotAuthorizedError, "No user found" unless user
    # Manually raise error to use a custom error message
    raise Pundit::NotAuthorizedError, "User is not permitted to use this liquid tag" unless user_allowed_to_use_tag?

    true
  end

  private

  def user_allowed_to_use_tag?
    user.public_send(record.user_authorization_method_name)
  end
end
