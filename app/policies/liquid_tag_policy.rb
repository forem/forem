# This Policy is responsible for enforcing weither or not the user can utilize
# the given liquid tag.
#
# @note Intentionally not inheriting from ApplicationPolicy because liquid tags
#       behave differently than the typical Model/Controller dynamic that Pundit
#       assumes.
class LiquidTagPolicy
  attr_reader :user, :liquid_tag

  # @param user [User]
  # @param liquid_tag [LiquidTagBase]
  def initialize(user, liquid_tag)
    @user = user
    @liquid_tag = liquid_tag
  end

  # Check if the given #user can utilize the given #liquid_tag
  #
  # @return [TrueClass] if the given liquid_tag is available to the user.

  # @raise [Pundit::NotAuthorizedError] if the liquid tag is not available to
  #        the given user.
  def initialize?
    # NOTE: This check the liquid tag then send that liquid tag's method to the
    # user is "fragile".  Would it make more sense to ask the liquid tag?  Or
    # the user given the liquid tag?  My inclination is ask the user (and by
    # extension the Authorizer).  But that is a future refactor.
    return true unless liquid_tag.user_authorization_method_name
    raise Pundit::NotAuthorizedError, "No user found" unless user
    # Manually raise error to use a custom error message
    raise Pundit::NotAuthorizedError, "User is not permitted to use this liquid tag" unless user_allowed_to_use_tag?

    true
  end

  private

  def user_allowed_to_use_tag?
    user.public_send(liquid_tag.user_authorization_method_name)
  end
end
