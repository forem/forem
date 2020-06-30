# Intentionally not inheriting from ApplicationPolicy because liquid tags behave
# differently than the typical Model/Controller dynamic that Pundit assumes.
class LiquidTagPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def initialize?
    return true unless record.class.const_defined?("VALID_ROLES")
    raise Pundit::NotAuthorizedError, "No user found" unless user
    # Manually raise error to use a custom error message
    raise Pundit::NotAuthorizedError, "User is not permitted to use this liquid tag" unless user_permitted_to_use_liquid_tag?

    true
  end

  private

  def user_permitted_to_use_liquid_tag?
    record.class::VALID_ROLES.any? { |valid_role| user_has_valid_role?(valid_role) }
  end

  def user_has_valid_role?(valid_role)
    # Splat array for single resource roles
    user.has_role?(*Array(valid_role))
  end
end
