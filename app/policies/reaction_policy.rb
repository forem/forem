# This policy assumes that we apply the same logic regardless of the reactable.
class ReactionPolicy < ApplicationPolicy
  # We don't have a robust concept of a Privileged Reaction class, but instead must switch the
  # reaction permissions based on the given category.
  def self.policy_query_for(category:)
    return :privileged_create? if ReactionCategory[category.to_s]&.privileged?

    :create?
  end

  def api?
    return true if user_any_admin?
  end

  def index?
    true
  end

  def create?
    true
  end

  def privileged_create?
    return true if user_any_admin?
    return true if user_trusted?

    false
  end
end
