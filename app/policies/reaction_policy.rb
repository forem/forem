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

  # Setting any status on any reaction stays admin-only. Confirming a flag has
  # consequences well beyond the reaction itself: confirmed comment vomits feed
  # Reaction.user_has_been_given_too_many_spammy_comment_reactions?, which can
  # suspend the author via Spam::Handler.
  def admin_update?
    user_any_admin?
  end

  # Support staff may additionally invalidate flags on comments, which zeroes
  # the reaction's points and restores the score of a downvoted comment.
  def admin_invalidate?
    admin_update? || (support_admin? && record.reactable_type == "Comment")
  end
end
