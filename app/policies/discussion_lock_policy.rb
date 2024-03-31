class DiscussionLockPolicy < ApplicationPolicy
  PERMITTED_ATTRIBUTES = %i[article_id notes reason].freeze

  def create?
    (user_author? || user_any_admin?) && !user.spam_or_suspended?
  end

  alias destroy? create?

  def permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  private

  def user_author?
    record.locking_user_id == user.id
  end
end
